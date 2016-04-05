# Copyright (C) 2016 Waylon Robertson of Winged 7 Limited, Wanganui, New Zealand (waylon@winged7.co.nz)

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::Teamwork_integration;

use 5.10.1;
use strict;
use warnings;
use parent qw(Bugzilla::Extension);
use Bugzilla::User;
# This code for this is in ../extensions/Teamwork_integration/lib/TeamworkAPI.pm
use Bugzilla::Extension::Teamwork_integration::TeamworkAPI;
use DateTime;
use DateTime::Format::MySQL;
use Data::Dumper;

our $VERSION = '0.1';

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook" 
# in the bugzilla directory) for a list of all available hooks.

# API notes
# $self->Get($requesturi)
# $self->Post($requesturi,$json_text)
# $personid = $self->GetPersonId($email)
# $locationurl = $self->InsertTimeEntry('task' or 'project',$id,$detailshash)
# $locationurl = $self->CreateTask($tasklistid, $name, $description, $creator_email, $assignee_email)

sub config_add_panels {
  my ($self, $args) = @_;
  my $modules = $args->{'panel_modules'};
  $modules->{'TeamworkIntegration'} = 'Bugzilla::Extension::Teamwork_integration::Params';
}

sub bug_start_of_update {
    my ($self, $args) = @_;
    my ($bug, $old_bug, $timestamp, $changes) =
        @$args{qw(bug old_bug timestamp changes)};
    if($bug->{teamwork_sync}){
        unless($bug->{teamwork_taskid}){
            my $taskid = teamwork_createtask($bug->{teamwork_tasklistid},$bug);
            $changes->{teamwork_taskid} = [0,$taskid];
            $bug->{teamwork_taskid} = $taskid;
            $bug->set('teamwork_taskid',$taskid);
        }
        if(my $added_comments = $bug->{added_comments} and $bug->{teamwork_taskid}) {
            my $bug_id = $added_comments->[0]->{bug_id};
            my $bug_when = $added_comments->[0]->{bug_when};
            my $work_time = $added_comments->[0]->{work_time};
            my $comment_text = $added_comments->[0]->{thetext};
            my $who_toid = $added_comments->[0]->{who};
            my $who_toinfo = new Bugzilla::User($who_toid);
            my $who_to_email = $who_toinfo->email();
            my $twh = _teamwork_handle();
            my $personid = $twh->GetPersonId($who_to_email);
            if ($work_time) {
                my ($hours, $frac) = split(/\./, $work_time);
                my $minutes;
                if($frac != 0){
                $minutes= 60 / 
                         (100 / $frac)}
                   else {$minutes=0};
                my $sec_elapsed = $hours * 60*60 + $minutes * 60;
                my $dt = DateTime::Format::MySQL->parse_datetime($bug_when);
                $dt->subtract(hours => $hours, minutes => $minutes);
                my $start_date = $dt->ymd("");
                my $start_hour = $dt->hour_1();
                my $start_minute = $dt->minute();
                my %detailhash = ('description' => $comment_text, 
                                  'who' => $personid, 
                                  'hours' => $hours,
                                  'minutes' => $minutes,
                                  'date' => $start_date,
                                  'time' => $start_hour.':'.$start_minute,
                                  'has-start-time' => 'true',);
                my $detailhashref = \%detailhash;
                my $location = $twh->CreateTimeEntry('task',$bug->{teamwork_taskid}, $detailhashref);
           }
           my %commentinfohash = ('author_id' => $personid,
                                  'body' => $comment_text);
           my $commentinfohashref = \%commentinfohash;
           $twh->CreateComment($bug->{teamwork_taskid},$commentinfohashref) if $comment_text;
        }
    }
}

sub object_columns {
    my ($self, $args) = @_;
    my ($class, $columns) = @$args{qw(class columns)};
    if ($class->isa('Bugzilla::Bug')) {
        push(@$columns, qw(teamwork_sync teamwork_tasklistid teamwork_taskid));
    }
}

sub bug_fields {
    my ($self, $args) = @_;
    my $fields = $args->{fields};
    push(@$fields, qw(teamwork_sync teamwork_tasklistid teamwork_taskid));
}

sub object_update_columns {
    my ($self, $args) = @_;
    my ($object, $columns) = @$args{qw(object columns)};
    if ($object->isa('Bugzilla::Bug')) {
        push(@$columns, qw(teamwork_sync teamwork_tasklistid teamwork_taskid));
    }
}

sub object_before_create {
    my ($self, $args) = @_;
    my ($class, $params) = @$args{qw(class params)};
    if ($class->isa('Bugzilla::Bug')) {
        my $input = Bugzilla->input_params; 
        $params->{teamwork_sync} = $input->{'teamwork_sync'} ? 1 : 0;
        $params->{teamwork_tasklistid} = $input->{'teamwork_tasklistid'};
        $params->{teamwork_taskid} = $input->{'teamwork_taskid'};
    }
}

sub object_end_of_set_all {
    my ($self, $args) = @_;
    my ($object) = $args->{object};
    if ($object->isa('Bugzilla::Bug')) {
        my $input = Bugzilla->input_params;
        my $sync = $input->{'teamwork_sync'} ? 1 : 0;
        if($sync){
          unless($input->{teamwork_taskid}){
            my $taskid = teamwork_createtask($input->{teamwork_tasklistid},$object);
            $input->{teamwork_taskid} = $taskid;
          }
        $object->set('teamwork_sync',$sync);
        $object->set('teamwork_tasklistid',$input->{'teamwork_tasklistid'});
        $object->set('teamwork_taskid',$input->{'teamwork_taskid'});
        }
    }
 }

# if Teamwork sync is true then:
# On bug creation, if Tasklistid is present and if task is not present, create a new task in tasklist
# else if Tasklistid is present, and task id is present, store values.
# else if tasklistid is not present, do nothing.

sub bug_end_of_create_validators {
    my ($self, $args) = @_;
    my $bug_params = $args->{'params'};
    if ($bug_params->{teamwork_sync}){
        if(my $tasklistid = $bug_params->{teamwork_tasklistid}){
            unless ($bug_params->{teamwork_taskid}){
                # Now create the task
                my $taskid = teamwork_createtask ($tasklistid, $bug_params);
                $bug_params->{teamwork_taskid} = $taskid if $taskid;
            }
        }
    }
}

sub teamwork_createtask {
    my $tasklistid = shift;
    my $bug_params = shift;
    my $twh = _teamwork_handle();
    my $reporterid = $bug_params->{reporter} || $bug_params->{reporter_id};
    my $reporterinfo = new Bugzilla::User($reporterid);
    my $assigned_toid = $bug_params->{assigned_to};
    my $assigned_toinfo = new Bugzilla::User($assigned_toid);
    my $reporter_email = $reporterinfo->email();
    my $assigned_to_email = $assigned_toinfo->email();
    my $text = $bug_params->{comment}->{thetext} || $bug_params->{comments}->[0]->{thetext} || " ";
    my $taskid = $twh->CreateTask($tasklistid,
                                    $bug_params->{short_desc},
                                    $text,
                                    $reporter_email,
                                    $assigned_to_email
                 );
    return $taskid;
}

 	

sub install_update_db {
    my $dbh = Bugzilla->dbh;
    my $field = new Bugzilla::Field({ name => 'teamwork_sync' });

    if (!$field) {
        Bugzilla::Field->create({ name => 'teamwork_sync', description => 'Teamwork Sync' });
    }

    my $field2 = new Bugzilla::Field({ name => 'teamwork_taskid' });

    if (!$field2) {
        Bugzilla::Field->create({ name => 'teamwork_taskid', description => 'Teamwork Task ID' });
    }

    my $field3 = new Bugzilla::Field({ name => 'teamwork_tasklistid' });

    if (!$field3) {
        Bugzilla::Field->create({ name => 'teamwork_tasklistid', description => 'Teamwork Tasklist ID' });
    }

    $dbh->bz_add_column('bugs', 'teamwork_sync', { TYPE => 'BOOLEAN' });
    $dbh->bz_add_column('bugs', 'teamwork_taskid', { TYPE => 'INTEGER' });
    $dbh->bz_add_column('bugs', 'teamwork_tasklistid', { TYPE => 'INTEGER' });
}

sub _teamwork_handle {
  my $apikey = Bugzilla->params->{'teamwork-default-apikey'};
  my $domain = Bugzilla->params->{'teamwork-domain'};
  my $twh = Bugzilla::Extension::Teamwork_integration::TeamworkAPI->new(apikey => $apikey, domain => $domain);
  return $twh;
}
__PACKAGE__->NAME;
