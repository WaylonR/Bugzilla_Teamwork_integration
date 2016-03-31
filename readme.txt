Bugzilla Extension Teamwork Integration
# Copyright (C) 2016 Waylon Robertson of Winged 7 Limited, Wanganui, New Zealand (waylon@winged7.co.nz)
This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. 
If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

This extension creates a partial one-way sync, or transfer of data between Bugzilla and the Team/Project management software.
Features currently include:
* Creates a task in Teamwork when a bugzilla user creates a bug, into the given tasklist. The initial comment is transferred over, as well as the reporter and the assignee / assigned to.
* On a existing bug, that has Teamwork Taskid given, new comments and time spend gets transferred over as changes are saved, including who commented and did the time.

This extension currently does not transfer anything else, like priority, status changes, or bug closing or deleting. Thats for another version to come.

Installation
1. Put this directory into the extensions directory of bugzilla, so it is extensions/Teamwork_integration
2. Create the following custom fields as follows:
CustomFieldName         Description		Type		Editable on Bug Creation
cf_teamwork_sync	Teamwork Sync		Drop Down	True
cf_teamwork_tasklistid	Teamwork Tasklist ID	Integer		True
cf_teamwork_taskid	Teamwork Task ID	Integer		True
3. run checksetup.pl to install the extensions prerequisite modules.
4. Restart your webserver if needed (for example if your running under mod_perl)

Further versions will have a more standard bugzilla extension installation procedure, and the Teamwork API archived on CPAN.

Usage:
	On a new bug, in advanced 
