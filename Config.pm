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

use constant NAME => 'Teamwork_integration';

use constant REQUIRED_MODULES => [
    {
        package => 'DateTime - A date and time object for Perl',
        module  => 'DateTime',
        version => 0,
    },
    {
        package => 'DateTime::Format::MySQL - Parse and format MySQL dates and times',
        module => 'DateTime::Format::MySQL',
        version => 0,
    },
    {
        package => 'Moo - Minimalist Object Orientation (with Moose compatibility)',
        module => 'Moo',
        version => 0,
    },
    {
        package => 'JSON - JSON (JavaScript Object Notation) encoder/decoder',
        module => 'JSON',
        version => 0,
    },
    {
        package => 'JSON::XS - JSON serialising/deserialising, done correctly and fast',
        module => 'JSON::XS',
        version => 0,
    },
    {
       package => 'LWP::UserAgent - Web user agent class',
       module => 'LWP::UserAgent',
       version => 0,
    },
];

use constant OPTIONAL_MODULES => [
];

__PACKAGE__->NAME;
