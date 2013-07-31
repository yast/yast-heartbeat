# encoding: utf-8

# ***************************************************************************
#
# Copyright (c) 2000 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# ***************************************************************************
#
# Copyright (c) 2000 - 2012 Novell, Inc.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************
# File:	clients/heartbeat.ycp
# Package:	Configuration of heartbeat
# Summary:	Main file
# Authors:	Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Main file for heartbeat configuration. Uses all other files.
module Yast
  module HeartbeatDialogsInclude
    def initialize_heartbeat_dialogs(include_target)
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"

      Yast.include include_target, "heartbeat/startup_conf.rb"
      Yast.include include_target, "heartbeat/node_conf.rb"
      Yast.include include_target, "heartbeat/media_conf.rb"
      Yast.include include_target, "heartbeat/auth_conf.rb"
      Yast.include include_target, "heartbeat/resources_conf.rb"
      Yast.include include_target, "heartbeat/stonith_conf.rb"
      Yast.include include_target, "heartbeat/timeouts_conf.rb"
      Yast.include include_target, "heartbeat/ipfail_conf.rb"
    end

    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))
      Heartbeat.AbortFunction = fun_ref(method(:PollAbort), "boolean ()")
      ret = Heartbeat.Read
      ret ? :next : :abort
    end

    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      Heartbeat.AbortFunction = fun_ref(method(:PollAbort), "boolean ()")
      ret = Heartbeat.Write
      ret ? :next : :abort
    end
  end
end
