# Copyright (C) 2016 Waylon Robertson of Winged 7 Limited, Wanganui, New Zealand (waylon@winged7.co.nz)

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This Source Code Form is "Incompatible With Secondary Licenses", as
# defined by the Mozilla Public License, v. 2.0.

package Bugzilla::Extension::Teamwork_integration::Params;

use 5.10.1;
use strict;
use warnings;

use Bugzilla::Config::Common;

our $sortkey = 300;

use constant get_param_list => (
  {
    name => 'teamwork-domain',
    type => 't',
    default => ''
  },
  {
    name => 'teamwork-default-apikey',
    type => 't',
    default => ''
  },
  {
    name => 'teamwork-default-tasklist-id',
    type => 't',
    default => ''
  },
);
