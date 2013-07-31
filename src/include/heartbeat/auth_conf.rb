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
  module HeartbeatAuthConfInclude
    def initialize_heartbeat_auth_conf(include_target)
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @method = ""
      @password = ""
    end

    def auth_conf_Read
      @method = Ops.get_string(Heartbeat.authkeys, "method", "")
      @password = Ops.get_string(Heartbeat.authkeys, "password", "")

      nil
    end

    def auth_conf_GetDialog
      VBox(
        Frame(
          _("Authentication Method"),
          HBox(
            RadioButtonGroup(
              Id("authmethod"),
              VBox(
                Left(
                  RadioButton(Id("crc"), Opt(:notify), _("CRC (No security)"))
                ),
                Left(RadioButton(Id("sha1"), Opt(:notify), _("SHA1"))),
                Left(RadioButton(Id("md5"), Opt(:notify), _("MD5")))
              )
            ),
            InputField(
              Id("authkey"),
              Opt(:hstretch),
              _("Authentication Key"),
              @password
            )
          )
        ),
        VStretch()
      )
    end

    def auth_conf_UpdateDialog
      method1 = Convert.to_string(
        UI.QueryWidget(Id("authmethod"), :CurrentButton)
      )
      UI.ChangeWidget(Id("authkey"), :Enabled, method1 != "crc")

      nil
    end


    def auth_conf_Write
      method1 = Convert.to_string(
        UI.QueryWidget(Id("authmethod"), :CurrentButton)
      )
      password1 = Convert.to_string(UI.QueryWidget(Id("authkey"), :Value))

      if method1 != "crc" && (password1 == "" || password1 == nil)
        Report.Error(_("Missing authentication key."))
        return false
      end

      if method1 != @method
        Ops.set(Heartbeat.authkeys, "modified", true)
        Ops.set(Heartbeat.authkeys, "method", method1)
      end

      if method1 != "crc" && @password != password1
        Ops.set(Heartbeat.authkeys, "modified", true)
        Ops.set(Heartbeat.authkeys, "password", password1)
      end

      if method1 == "crc" && @password != ""
        Ops.set(Heartbeat.authkeys, "modified", true)
        Ops.set(Heartbeat.authkeys, "password", "")
      end

      true
    end


    def ConfigureAuthDialog
      auth_conf_Read

      my_SetContents("auth_conf", auth_conf_GetDialog)

      UI.ChangeWidget(
        Id("authmethod"),
        :CurrentButton,
        @method == "" ? "crc" : @method
      )

      ret = nil
      while true
        Wizard.SelectTreeItem("auth_conf")

        auth_conf_UpdateDialog

        ret = UI.UserInput

        if ret == :help
          myHelp("auth_conf")
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        next if ret == "crc" || ret == "md5" || ret == "sha1"

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :next || ret == :back ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !auth_conf_Write

          if ret != :next && ret != :back
            ret = Builtins.symbolof(Builtins.toterm(ret))
          end

          break
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end

      deep_copy(ret)
    end
  end
end
