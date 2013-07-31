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
  module HeartbeatStartupConfInclude
    def initialize_heartbeat_startup_conf(include_target)
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Service"
      Yast.import "Heartbeat"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"
    end

    def ConfigureStartUpDialog
      boot = Heartbeat.start_daemon

      _Tbooting = Frame(
        _("Booting"),
        Left(
          RadioButtonGroup(
            Id("server_type"),
            VBox(
              Left(
                RadioButton(
                  Id("on"),
                  _("On -- Start Heartbeat Server Now and when Booting")
                )
              ),
              Left(
                RadioButton(Id("off"), _("Off -- Server Only Starts Manually"))
              ),
              VSpacing(1)
            )
          )
        )
      )

      _Tonoff = Frame(
        _("Switch On and Off"),
        Left(
          HSquash(
            VBox(
              HBox(
                Label(_("Current Status: ")),
                ReplacePoint(Id("status_rp"), Empty()),
                HStretch()
              ),
              PushButton(
                Id("start_now"),
                Opt(:hstretch),
                _("Start Heartbeat Server Now")
              ),
              PushButton(
                Id("stop_now"),
                Opt(:hstretch),
                _("Stop Heartbeat Server Now")
              )
            )
          )
        )
      )

      contents = Empty()
      if Heartbeat.firstrun
        contents = VBox(_Tbooting, VStretch())
      else
        contents = VBox(_Tbooting, VSpacing(1), _Tonoff, VStretch())
      end


      my_SetContents("startup_conf", contents)

      UI.ChangeWidget(Id("server_type"), :CurrentButton, boot ? "on" : "off")

      ret = nil
      while true
        status = Service.Status("heartbeat")

        if !Heartbeat.firstrun
          UI.ChangeWidget(Id("start_now"), :Enabled, status != 0)
          UI.ChangeWidget(Id("stop_now"), :Enabled, status == 0)

          UI.ReplaceWidget(
            Id("status_rp"),
            Label(
              status == 0 ?
                _("Heartbeat server is running.") :
                _("Heartbeat server is not running.")
            )
          )
        end

        ret = UI.UserInput

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        break if ret == :next || ret == :back

        if ret == "start_now"
          Report.Error(Service.Error) if !Service.Start("heartbeat")
          next
        end

        if ret == "stop_now"
          Report.Error(Service.Error) if !Service.Stop("heartbeat")
          next
        end

        if ret == :help
          myHelp("startup_conf")
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if Builtins.contains(@DIALOG, Convert.to_string(ret))
          ret = Builtins.symbolof(Builtins.toterm(ret))
          break
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end

      boot1 = Convert.to_string(
        UI.QueryWidget(Id("server_type"), :CurrentButton)
      )
      if boot1 == "off" && boot || boot1 == "on" && !boot
        Heartbeat.start_daemon_modified = true
        Heartbeat.start_daemon = !boot
      end

      deep_copy(ret)
    end
  end
end
