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
  module HeartbeatCommonInclude
    def initialize_heartbeat_common(include_target)
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"
      Yast.import "Popup"
      Yast.import "CWM"

      #include "heartbeat/helps.ycp";

      @DIALOG =
        #    "stonith_conf",
        #     "resources_conf",
        #     "timeouts_conf",
        #     "ipfail_conf",
        #     "group_conf"
        ["node_conf", "auth_conf", "media_conf", "startup_conf"]

      @PARENT = { "group_conf" => "ipfail_conf" }

      @NAME = {
        "startup_conf"   => _("Start-up Configuration"),
        "node_conf"      => _("Node Configuration"),
        "media_conf"     => _("Media Configuration"),
        "auth_conf"      => _("Authentication Keys"),
        "resources_conf" => _("Resources"),
        "stonith_conf"   => _("STONITH Configuration"),
        "timeouts_conf"  => _("Time-outs"),
        "ipfail_conf"    => _("IP Fail"),
        "group_conf"     => _("Ping Groups")
      }
    end

    def Modified
      Heartbeat.Modified
    end

    def ReallyAbort
      !Heartbeat.Modified || Popup.ReallyAbort(true)
    end

    def PollAbort
      UI.PollInput == :abort
    end

    def cmpList(a, b)
      a = deep_copy(a)
      b = deep_copy(b)
      same = true
      if Builtins.size(a) != Builtins.size(b)
        same = false 
        # TODO!!
      end
      false
    end

    def my_SetContents(conf, contents)
      contents = deep_copy(contents)
      Wizard.SetContents(
        Ops.add("Heartbeat - ", Ops.get_string(@NAME, conf, "")),
        contents,
        Ops.get_string(@HELPS, conf, ""),
        true,
        true
      )

      if UI.WidgetExists(Id(:wizardTree))
        #	UI::ChangeWidget(`id(`wizardTree), `CurrentItem, current_dialog);
        UI.SetFocus(Id(:wizardTree))
      end

      if Heartbeat.firstrun
        UI.ChangeWidget(Id(:back), :Enabled, conf != "node_conf")
        if conf == "startup_conf"
          UI.WizardCommand(term(:SetNextButtonLabel, Label.FinishButton))
          Wizard.SetNextButton(:next, Label.FinishButton)
        else
          UI.WizardCommand(term(:SetNextButtonLabel, Label.NextButton))
          Wizard.SetNextButton(:next, Label.NextButton)
        end
      end

      nil
    end

    def myHelp(help)
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          VSpacing(16),
          VBox(
            HSpacing(60),
            VSpacing(0.5),
            RichText(Ops.get_string(@HELPS, help, "")),
            VSpacing(1.5),
            PushButton(Id(:ok), Opt(:default, :key_F10), Label.OKButton)
          )
        )
      )

      UI.SetFocus(Id(:ok))
      UI.UserInput
      UI.CloseDialog

      nil
    end
  end
end
