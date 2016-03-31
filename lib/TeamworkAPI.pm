# Copyright (C) 2016 Waylon Robertson of Winged 7 Limited, Wanganui, New Zealand (waylon@winged7.co.nz)

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::Teamwork_integration::TeamworkAPI;
use Moo;
use JSON;
use JSON::XS ();
use LWP::UserAgent;
 
has 'lwp' => (is => 'rw', default => sub { my $lwpo = LWP::UserAgent->new();$lwpo->agent('Bugzilla/5.0');return $lwpo;});
my $domain = 'https://winged7.teamwork.com';
my $apikey = 'very769toe';

sub Get {
    my $self = shift;
    my $lwp = $self->lwp;
    my $requesturi = shift;
    my $url = $domain.$requesturi;
    my $req = HTTP::Request->new( 'GET', $url );

    $req->header( 'Content-Type' => 'application/json' );
    $req->authorization_basic($apikey,"xxx");

    my $resp = $lwp->request($req);
    my $json_str = $resp->content;
    my $json_obj = new JSON::XS;
    my $json_hashref = $json_obj->allow_nonref->utf8->relaxed->decode($json_str);
    return $json_hashref;
}

sub Post {
    my $self = shift;
    my $lwp = $self->lwp;
    my $requesturi = shift;
    my $json_text = shift;
    my $url = $domain.$requesturi;

    my $req = HTTP::Request->new( 'POST', $url );

    $req->header( 'Content-Type' => 'application/json' );
    $req->content( $json_text );
    $req->authorization_basic($apikey,"xxx");
    my $res = $lwp->request($req);
    return $res;
}

# sub GetPersonId
sub GetPersonId {
    my $self = shift;
    my $email = shift;
if (!$email){return "-1"};
    my $json_hashref = $self->Get('/people.json?emailaddress='.$email);
    my $personid = $json_hashref->{people}->[0]->{id};
    return $personid;
}

# sub CreateComment
sub CreateComment {
    my $self = shift;
    my $taskId = shift;
    my $commentinfohashref = shift;
    my %commenthash = ( 'comment' => $commentinfohashref );
    my $json_text = encode_json \%commenthash;
    my $requesturi = '/tasks/'.$taskId.'/comments.json';

    my $res = $self->Post($requesturi,$json_text);
    if( $res->code ne '201') {
        return;
    };
    my $location = $res->header('Location');
    return $location;
}

# sub CreateTimeEntry
sub CreateTimeEntry {
    my $self = shift;
    my $mode = shift;
    my $ProgOrTaskID = shift;
    my $detailshashref = shift;
    my %timehash = ( 'time-entry' => $detailshashref );
    my $json_text = encode_json \%timehash;
    my $requesturi;
    if ($mode eq 'task') {
        $requesturi = '/tasks/'.$ProgOrTaskID.'/time_entries.json';
    } elsif ($mode eq 'project') {
        $requesturi = '/projects/'.$ProgOrTaskID.'/time_entries.json';
    } else { return '--- Bad insert mode.' };

    my $res = $self->Post($requesturi,$json_text);
    if( $res->code ne '201') {
        return;
    };
    my $location = $res->header('Location');
    return $location;
}

sub CreateTask {
    my $self = shift;
    my $tasklistid = shift;
    my $name = shift;
    my $description = shift;
    my $creator_email = shift;
    my $creator_id = $self->GetPersonId($creator_email);
    my $assignee_email = shift;
    my $personid = $self->GetPersonId($assignee_email);
    $personid = $personid ? $personid : "-1";
    my %taskhash = ('content' => $name, 
                                    'description' => $description,
                                    'creator-id' => $creator_id, 
                                    'responsible-party-id' => $personid
                   );
    my $taskhashref = \%taskhash;
    my %todohash = ( 'todo-item' => $taskhashref );
    my $requesturi = '/tasklists/'.$tasklistid.'/tasks.json';
    my $json_text = encode_json \%todohash;
    my $res = $self->Post($requesturi, $json_text);

    if( $res->code ne '201') {
        return;
    }
    my $taskid = $res->header('id');
    return $taskid;
}


    
# This file can be loaded by your extension via 
# "use Bugzilla::Extension::Teamwork-integration::TeamworkAPI". You can put functions
# used by your extension in here.

1;
