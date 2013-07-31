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
# Package:	Configuration of heartbeat
# Authors:	Martin Lazar <mlazar@suse.cz>
#
# $Id$
module Yast
  module HeartbeatTimeoutsConfInclude
    def initialize_heartbeat_timeouts_conf(include_target)
      Yast.import "UI"
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"
      Yast.import "Report"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"
    end

    def timeouts_conf_Read
      to = {}

      Builtins.foreach(["keepalive", "deadtime", "warntime", "initdead"]) do |key|
        x = Ops.get_string(Heartbeat.config, key, "")
        Ops.set(to, key, Builtins.tointeger(x)) if x != "" && x != nil
      end

      Ops.set(to, "watchdog", Ops.get_string(Heartbeat.config, "watchdog", ""))
      Ops.set(to, "wd_enab", Ops.get_string(to, "watchdog", "") != "")
      deep_copy(to)
    end

    def timeouts_conf_Current(old_to)
      old_to = deep_copy(old_to)
      to = {}

      Builtins.foreach(["keepalive", "deadtime", "warntime", "initdead"]) do |key|
        Ops.set(to, key, Convert.to_integer(UI.QueryWidget(Id(key), :Value)))
      end

      wd_enab = Convert.to_string(UI.QueryWidget(Id("wd_enab"), :CurrentButton))
      wd_dev = Convert.to_string(UI.QueryWidget(Id("wd_dev"), :Value))
      if wd_enab == "disable"
        Ops.set(to, "watchdog", "")
        Ops.set(to, "wd_enab", false)
      else
        Ops.set(to, "watchdog", wd_dev)
        Ops.set(to, "wd_enab", true)
      end

      deep_copy(to)
    end

    def timeouts_conf_Write(old, new)
      old = deep_copy(old)
      new = deep_copy(new)
      Builtins.foreach(["keepalive", "deadtime", "warntime", "initdead"]) do |key|
        if Ops.get_integer(old, key, -1) != Ops.get_integer(new, key, -1)
          Ops.set(
            Heartbeat.config,
            key,
            Builtins.tostring(Ops.get_integer(new, key, -1))
          )
          Ops.set(Heartbeat.config, "modified", true)
        end
      end

      if Ops.get_string(old, "watchdog", "") !=
          Ops.get_string(new, "watchdog", "")
        Ops.set(Heartbeat.config, "modified", true)
        if Ops.get_string(new, "watchdog", "") == ""
          Heartbeat.config = Builtins.filter(
            Convert.convert(
              Heartbeat.config,
              :from => "map",
              :to   => "map <string, any>"
            )
          ) { |k, v| k != "watchdog" }
        else
          Ops.set(
            Heartbeat.config,
            "watchdog",
            Ops.get_string(new, "watchdog", "")
          )
        end
      end

      true
    end

    def timeouts_conf_SetContents(to)
      to = deep_copy(to)
      watchdog = Ops.get_string(to, "watchdog", "")
      watchdogs = Builtins.union([watchdog], ["/dev/watchdog"])
      watchdogs = Builtins.filter(
        Convert.convert(watchdogs, :from => "list", :to => "list <string>")
      ) { |s| s != "" }

      contents = VBox(
        Left(
          HSquash(
            VBox(
              IntField(
                Id("keepalive"),
                _("Keep Alive"),
                1,
                1000,
                Ops.get_integer(to, "keepalive", 2)
              ),
              VSpacing(1),
              IntField(
                Id("deadtime"),
                _("Dead Time"),
                1,
                1000,
                Ops.get_integer(to, "deadtime", 30)
              ),
              VSpacing(1),
              IntField(
                Id("warntime"),
                _("Warn Time"),
                1,
                1000,
                Ops.get_integer(to, "warntime", 10)
              ),
              VSpacing(1),
              IntField(
                Id("initdead"),
                _("Init Dead Time"),
                1,
                1000,
                Ops.get_integer(to, "initdead", 120)
              )
            )
          )
        ),
        VSpacing(1),
        Frame(
          _("Watchdog Timer"),
          HBox(
            RadioButtonGroup(
              Id("wd_enab"),
              VBox(
                RadioButton(
                  Id("enable"),
                  Opt(:notify),
                  _("Enable"),
                  Ops.get_boolean(to, "wd_enab", true)
                ),
                RadioButton(
                  Id("disable"),
                  Opt(:notify),
                  _("Disable"),
                  !Ops.get_boolean(to, "wd_enab", true)
                )
              )
            ),
            HStretch(),
            ComboBox(
              Id("wd_dev"),
              Opt(:editable),
              _("Watchdog Device"),
              watchdogs
            ),
            HStretch()
          )
        ),
        VStretch()
      )

      my_SetContents("timeouts_conf", contents)
      UI.ChangeWidget(
        Id("wd_dev"),
        :Value,
        watchdog == "" ? "/dev/watchdog" : watchdog
      )

      nil
    end

    def timeouts_conf_UpdateDialog(to)
      to = deep_copy(to)
      UI.ChangeWidget(
        Id("wd_dev"),
        :Enabled,
        Ops.get_boolean(to, "wd_enab", true)
      )

      nil
    end

    def ConfigureTimeoutsDialog
      old = timeouts_conf_Read
      cur = deep_copy(old)

      timeouts_conf_SetContents(old)

      ret = nil
      while true
        Wizard.SelectTreeItem("timeouts_conf")

        timeouts_conf_UpdateDialog(cur)

        ret = UI.UserInput

        cur = timeouts_conf_Current(cur)

        next if ret == "enable" || ret == "disable"

        if ret == :help
          myHelp("timeouts_conf")
          next
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :next || ret == :back || ret == :wizardTree ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !timeouts_conf_Write(old, cur)

          if ret == :wizardTree
            ret = Convert.to_string(
              UI.QueryWidget(Id(:wizardTree), :CurrentItem)
            )
          end

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
