Bugzilla Extension Teamwork Integration
# Copyright (C) 2016 Waylon Robertson of Winged 7 Limited, Wanganui, New Zealand (waylon@winged7.co.nz)
This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. 
If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

This extension creates a partial one-way sync, or transfer of data between Bugzilla and the Team/Project management software.
Features currently include:
* Creates a task in Teamwork when a bugzilla user creates a bug, into the given tasklist. The initial comment is transferred over, as well as the reporter and the assignee / assigned to.
* On a existing bug, if no teamwork taskid exists on it, a new teamwork task is created, the comments and time spent gets transferred over as changes are saved, including who commented. Only new time spent gets transferred to teamwork, bugzilla does not track time at a per event level, as teamwork does.

This extension currently does not transfer anything else, like priority, status changes, or bug closing or deleting. Thats for another version to come.

Installation
1. Put this directory into the extensions directory of bugzilla, so it is extensions/Teamwork_integration
3. run checksetup.pl to install the extensions prerequisite modules.
4. Restart your webserver if needed (for example if your running under mod_perl)
Thats it. The standard Bugzilla extension installation.

Usage:
	On a new bug, check the "Enable Teamwork Sync" checkbox down by the submit button, put the Teamwork tasklist id number into Teamwork Tasklist id. Fill out the bug as normal, and submit. 

The Teamwork tasklist id comes from Teamwork, get it by accessing a tasklist, the id is at the end of the url. For example:
https://winged7.teamwork.com/tasklists/674540

