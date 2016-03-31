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

our $VERSION = '0.02';

# See the documentation of Bugzilla::Hook ("perldoc Bugzilla::Hook" 
# in the bugzilla directory) for a list of all available hooks.

# API notes
# $self->Get($requesturi)
# $self->Post($requesturi,$json_text)
# $personid = $self->GetPersonId($email)
# $locationurl = $self->InsertTimeEntry('task' or 'project',$id,$detailshash)
# $locationurl = $self->CreateTask($tasklistid, $name, $description, $creator_email, $assignee_email)




sub object_end_of_set_all {
    my ($self, $args) = @_;
    my ($object, $params) = @$args{qw(object params)};
    if ($object->isa('Bugzilla::Bug')) {
        if(!$object->{cf_teamwork_taskid} && $object->{cf_teamwork_sync} ne '---') {
            my $taskid = teamwork_createtask($object->cf_teamwork_tasklistid,$object);
            $object->{cf_teamwork_taskid} = $taskid;
        }
    }
}

sub bug_start_of_update {
    my ($self, $args) = @_;
    my ($bug, $old_bug, $timestamp, $changes) =
        @$args{qw(bug old_bug timestamp changes)};
    if($bug->{cf_teamwork_sync} ne '---'){
        unless($bug->{cf_teamwork_taskid}){
            my $taskid = teamwork_createtask($bug->cf_teamwork_tasklistid,$bug);
            $changes->{cf_teamwork_taskid} = [0,$taskid];
            $bug->{cf_teamwork_taskid} = $taskid;
        }
        if(my $added_comments = $bug->{added_comments} and $bug->{cf_teamwork_taskid}) {
            my $bug_id = $added_comments->[0]->{bug_id};
            my $bug_when = $added_comments->[0]->{bug_when};
            my $work_time = $added_comments->[0]->{work_time};
            my $comment_text = $added_comments->[0]->{thetext};
            my $who_toid = $added_comments->[0]->{who};
            my $who_toinfo = new Bugzilla::User($who_toid);
            my $who_to_email = $who_toinfo->email();
            my $twapi = new Bugzilla::Extension::Teamwork_integration::TeamworkAPI;
            my $personid = $twapi->GetPersonId($who_to_email);
            if ($work_time) {
                my ($hours, $frac) = split(/\./, $work_time);
                my $minutes;
                if($frac){$minutes= 60 / (100 / $frac)} else {$minutes=0};
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
                my $location = $twapi->CreateTimeEntry('task',$bug->{cf_teamwork_taskid}, $detailhashref);
           }
           my %commentinfohash = ('author_id' => $personid,
                                  'body' => $comment_text);
           my $commentinfohashref = \%commentinfohash;
           $twapi->CreateComment($bug->{cf_teamwork_taskid},$commentinfohashref) if $comment_text;
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
    if ($bug_params->{cf_teamwork_sync}){
        if(my $tasklistid = $bug_params->{cf_teamwork_tasklistid}){
            unless ($bug_params->{cf_teamwork_taskid}){
                # Now create the task
                my $taskid = teamwork_createtask ($tasklistid, $bug_params);
                $bug_params->{cf_teamwork_taskid} = $taskid if $taskid;
            }
        }
    }
}

sub teamwork_createtask {
    my $tasklistid = shift;
    my $bug_params = shift;
    my $twapi = new Bugzilla::Extension::Teamwork_integration::TeamworkAPI;
                my $reporterid = $bug_params->{reporter} || $bug_params->{reporter_id};
                my $reporterinfo = new Bugzilla::User($reporterid);
                my $assigned_toid = $bug_params->{assigned_to};
                my $assigned_toinfo = new Bugzilla::User($assigned_toid);
                my $reporter_email = $reporterinfo->email();
                my $assigned_to_email = $assigned_toinfo->email();
warn "Dumper says: ". Dumper $bug_params;
                my $text = $bug_params->{comment}->{thetext} || $bug_params->{comments}->[0]->{thetext};
                my $taskid = $twapi->CreateTask($tasklistid,
                                                     $bug_params->{short_desc},
                                                     $text,
                                                     $reporter_email,
                                                     $assigned_to_email
                                                    );
                 return $taskid;
}

__PACKAGE__->NAME;
