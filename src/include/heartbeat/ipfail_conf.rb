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
  module HeartbeatIpfailConfInclude
    def initialize_heartbeat_ipfail_conf(include_target)
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"
      Yast.import "Report"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @ipfail_re = "/heartbeat/ipfail$"
    end

    def ipfail_conf_Read
      f = {}

      respawn = Ops.get_list(Heartbeat.config, "respawn", [])
      Ops.set(f, "enab", false)
      Builtins.foreach(respawn) do |s|
        Ops.set(f, "enab", true) if Builtins.regexpmatch(s, @ipfail_re)
      end

      Ops.set(f, "ping", Ops.get_list(Heartbeat.config, "ping", []))

      deep_copy(f)
    end

    def ipfail_conf_Write(old, new)
      old = deep_copy(old)
      new = deep_copy(new)
      if Ops.get_boolean(old, "enab", true) !=
          Ops.get_boolean(new, "enab", true)
        Ops.set(Heartbeat.config, "modified", true)
        respawn = Ops.get_list(Heartbeat.config, "respawn", [])
        respawn = Builtins.filter(respawn) do |s|
          !Builtins.regexpmatch(s, @ipfail_re)
        end
        if Ops.get_boolean(new, "enab", true)
          unamemap = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), "uname -m")
          )
          machine = Builtins.deletechars(
            Ops.get_string(unamemap, "stdout", ""),
            "\n"
          )
          if machine == "x86_64"
            respawn = Builtins.add(
              respawn,
              "hacluster /usr/lib64/heartbeat/ipfail"
            )
          else
            respawn = Builtins.add(
              respawn,
              "hacluster /usr/lib/heartbeat/ipfail"
            )
          end
        end
        Ops.set(Heartbeat.config, "respawn", respawn)
      end

      same = true
      if Builtins.size(Ops.get_list(old, "ping", [])) !=
          Builtins.size(Ops.get_list(new, "ping", []))
        same = false
      else
        i = Builtins.size(Ops.get_list(new, "ping", []))
        while Ops.greater_or_equal(i, 0) &&
            Ops.get_string(old, ["ping", i], "") ==
              Ops.get_string(new, ["ping", i], "")
          i = Ops.subtract(i, 1)
        end
        same = false if Ops.greater_or_equal(i, 0)
      end
      if !same
        Ops.set(Heartbeat.config, "modified", true)
        Ops.set(Heartbeat.config, "ping", Ops.get_list(new, "ping", []))
      end

      true
    end

    def ipfail_conf_updatePingList(l, selected)
      l = deep_copy(l)
      UI.ReplaceWidget(
        Id("ping_list_rp"),
        SelectionBox(Id("ping_list"), _("Node List"), l)
      )
      if Ops.greater_than(Builtins.size(l), 0) && selected != "" &&
          selected != nil &&
          Builtins.contains(l, selected)
        UI.ChangeWidget(Id("ping_list"), :CurrentItem, selected)
      end

      nil
    end

    def ipfail_conf_SetDialog(f)
      f = deep_copy(f)
      #    term TEnab = `Left(`CheckBox(`id("enable"), _("Enable IP Fail")));
      _TEnab = Left(
        RadioButtonGroup(
          Id("enab"),
          HBox(
            RadioButton(
              Id("enable"),
              _("Enable"),
              Ops.get_boolean(f, "enab", true)
            ),
            RadioButton(
              Id("disable"),
              _("Disable"),
              !Ops.get_boolean(f, "enab", true)
            )
          )
        )
      )

      _TPing = VBox(
        VSquash(
          HBox(
            HWeight(
              9,
              Frame(
                _("Ping to Node"),
                HBox(TextEntry(Id("ping_ip"), _("IP Address")))
              )
            ),
            HWeight(
              2,
              VBox(
                VStretch(),
                PushButton(Id("ping_add"), Opt(:hstretch), Label.AddButton)
              )
            )
          )
        ),
        VSpacing(0.5),
        HBox(
          HWeight(9, ReplacePoint(Id("ping_list_rp"), Empty())),
          HWeight(
            2,
            VBox(
              VSpacing(1),
              PushButton(Id("ping_del"), Opt(:hstretch), Label.DeleteButton),
              VStretch()
            )
          )
        )
      )

      contents = VBox(VSquash(_TEnab), VSpacing(1), _TPing)

      my_SetContents("ipfail_conf", contents)

      ipfail_conf_updatePingList(
        Ops.get_list(f, "ping", []),
        Ops.get_string(f, ["ping", 0], "")
      )

      nil
    end

    def ipfail_conf_UpdateDialog(f)
      f = deep_copy(f)
      UI.ChangeWidget(
        Id("ping_del"),
        :Enabled,
        Ops.greater_than(Builtins.size(Ops.get_list(f, "ping", [])), 0)
      )

      nil
    end

    def ipfail_conf_Current(old)
      old = deep_copy(old)
      f = {}

      Ops.set(
        f,
        "enab",
        "enable" ==
          Convert.to_string(UI.QueryWidget(Id("enab"), :CurrentButton))
      )
      Ops.set(f, "ping", Ops.get_list(old, "ping", []))
      deep_copy(f)
    end

    def ConfigureIpfailDialog
      old = ipfail_conf_Read
      cur = deep_copy(old)

      ipfail_conf_SetDialog(old)

      ret = nil
      while true
        Wizard.SelectTreeItem("ipfail_conf")

        ipfail_conf_UpdateDialog(cur)

        ret = UI.UserInput

        cur = ipfail_conf_Current(cur)

        if ret == "ping_del"
          sel = Convert.to_string(UI.QueryWidget(Id("ping_list"), :CurrentItem))
          Ops.set(cur, "ping", Builtins.filter(Ops.get_list(cur, "ping", [])) do |s|
            s != sel
          end)
          ipfail_conf_updatePingList(
            Ops.get_list(cur, "ping", []),
            Ops.get_string(cur, ["ping", 0], "")
          )
          next
        end

        if ret == "ping_add"
          ip = Convert.to_string(UI.QueryWidget(Id("ping_ip"), :Value))
          if !IP.Check4(ip)
            Report.Error(IP.Valid4)
            next
          end
          if Builtins.contains(Ops.get_list(cur, "ping", []), ip)
            Report.Error(_("Specified IP address is already present."))
            next
          end
          Ops.set(cur, "ping", Builtins.add(Ops.get_list(cur, "ping", []), ip))
          ipfail_conf_updatePingList(Ops.get_list(cur, "ping", []), ip)
          next
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :help
          myHelp("ipfails_conf")
          next
        end

        if ret == :next || ret == :back || ret == :wizardTree ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !ipfail_conf_Write(old, cur)

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


    # ping group configuration

    def group_conf_Read
      g = {}

      Builtins.foreach(Ops.get_list(Heartbeat.config, "ping_group", [])) do |s|
        l = Builtins.splitstring(s, " \t")
        name = Ops.get_string(l, 0, "")
        Ops.set(g, name, Builtins.remove(l, 0)) if name != ""
      end

      deep_copy(g)
    end

    def group_conf_Write(old, new)
      old = deep_copy(old)
      new = deep_copy(new)
      same = true
      if Builtins.size(old) != Builtins.size(new)
        same = false
      else
        Builtins.foreach(
          Convert.convert(old, :from => "map", :to => "map <string, list>")
        ) do |key, l|
          if same &&
              Builtins.mergestring(
                Convert.convert(l, :from => "list", :to => "list <string>"),
                " "
              ) !=
                Builtins.mergestring(Ops.get_list(new, key, []), " ")
            same = false
          end
        end
      end

      if !same
        Ops.set(Heartbeat.config, "modified", true)
        pg = []
        Builtins.foreach(
          Convert.convert(new, :from => "map", :to => "map <string, list>")
        ) do |key, l|
          s = key
          if Ops.greater_than(Builtins.size(l), 0)
            s = Ops.add(
              Ops.add(s, " "),
              Builtins.mergestring(
                Convert.convert(l, :from => "list", :to => "list <string>"),
                " "
              )
            )
          end
          pg = Builtins.add(pg, s)
        end
        Ops.set(Heartbeat.config, "ping_group", pg)
      end

      true
    end

    def group_conf_updateList(g, sel)
      g = deep_copy(g)
      items = []

      Builtins.foreach(
        Convert.convert(g, :from => "map", :to => "map <string, list>")
      ) do |key, ip|
        items = Builtins.add(
          items,
          Item(
            Id(key),
            key,
            Builtins.mergestring(
              Convert.convert(ip, :from => "list", :to => "list <string>"),
              " "
            )
          )
        )
      end

      UI.ChangeWidget(Id("group_list"), :Items, items)

      if Ops.greater_than(Builtins.size(g), 0) && sel != "" && sel != nil &&
          Builtins.haskey(g, sel)
        UI.ChangeWidget(Id("group_list"), :CurrentItem, sel)
      end

      nil
    end

    def group_conf_UpdateDialog(g)
      g = deep_copy(g)
      UI.ChangeWidget(
        Id("group_edit"),
        :Enabled,
        Ops.greater_than(Builtins.size(g), 0)
      )
      UI.ChangeWidget(
        Id("group_del"),
        :Enabled,
        Ops.greater_than(Builtins.size(g), 0)
      )

      nil
    end

    def group_conf_Current(old)
      old = deep_copy(old)
      deep_copy(old)
    end

    def group_conf_SetDialog(g)
      g = deep_copy(g)
      contents = VBox(
        VSquash(
          HBox(
            HWeight(
              9,
              Frame(
                _("Ping Group"),
                HBox(
                  HSquash(TextEntry(Id("group_name"), _("Group Name"))),
                  HSpacing(1),
                  TextEntry(Id("group_ip"), _("List of IP Addresses"))
                )
              )
            ),
            HWeight(
              2,
              VBox(
                VStretch(),
                PushButton(Id("group_add"), Opt(:hstretch), Label.AddButton),
                PushButton(Id("group_edit"), Opt(:hstretch), Label.EditButton)
              )
            )
          )
        ),
        VSpacing(0.5),
        HBox(
          HWeight(
            9,
            Table(
              Id("group_list"),
              Opt(:notify, :immediate),
              Header(_("Group Name"), _("IP Addresses"))
            )
          ),
          HWeight(
            2,
            VBox(
              VSpacing(1),
              PushButton(Id("group_del"), Opt(:hstretch), Label.DeleteButton),
              VStretch()
            )
          )
        )
      )

      my_SetContents("group_conf", contents)

      group_conf_updateList(g, nil)

      nil
    end

    def ConfigurePingGroupDialog
      old = group_conf_Read
      cur = deep_copy(old)

      group_conf_SetDialog(old)

      ret = nil
      while true
        Wizard.SelectTreeItem("group_conf")

        group_conf_UpdateDialog(cur)

        ret = UI.UserInput

        cur = group_conf_Current(cur)

        if ret == "group_add"
          name = Convert.to_string(UI.QueryWidget(Id("group_name"), :Value))
          iplist = Convert.to_string(UI.QueryWidget(Id("group_ip"), :Value))
          ip = Builtins.splitstring(iplist, " \t")

          if name == "" || name == nil
            Report.Error(_("Group name is required."))
            next
          end

          if Builtins.haskey(cur, name)
            Report.Error(_("Specified group name is already present."))
            next
          end

          ipok = true
          Builtins.foreach(
            Convert.convert(ip, :from => "list", :to => "list <string>")
          ) { |s| ipok = false if !IP.Check4(s) }
          if !ipok
            Report.Error(_("Bad list of IP addresses."))
            next
          end

          Ops.set(cur, name, ip)
          group_conf_updateList(cur, name)
          next
        end

        if ret == "group_edit"
          name = Convert.to_string(UI.QueryWidget(Id("group_name"), :Value))
          iplist = Convert.to_string(UI.QueryWidget(Id("group_ip"), :Value))
          ip = Builtins.splitstring(iplist, " \t")

          if name == "" || name == nil
            Report.Error(_("Group name is required."))
            next
          end

          ipok = true
          Builtins.foreach(
            Convert.convert(ip, :from => "list", :to => "list <string>")
          ) { |s| ipok = false if !IP.Check4(s) }
          if !ipok
            Report.Error(_("Bad list of IP addresses."))
            next
          end

          key = Convert.to_string(
            UI.QueryWidget(Id("group_list"), :CurrentItem)
          )
          cur = Builtins.filter(
            Convert.convert(cur, :from => "map", :to => "map <string, list>")
          ) { |s, l| s != key }

          Ops.set(cur, name, ip)
          group_conf_updateList(cur, name)
          next
        end

        if ret == "group_del"
          key = Convert.to_string(
            UI.QueryWidget(Id("group_list"), :CurrentItem)
          )
          cur = Builtins.filter(
            Convert.convert(cur, :from => "map", :to => "map <string, list>")
          ) { |s, l| s != key }
          group_conf_updateList(cur, nil)
          next
        end

        if ret == "group_list"
          key = Convert.to_string(
            UI.QueryWidget(Id("group_list"), :CurrentItem)
          )
          UI.ChangeWidget(Id("group_name"), :Value, key)
          UI.ChangeWidget(
            Id("group_ip"),
            :Value,
            Builtins.mergestring(Ops.get_list(cur, key, []), " ")
          )
          next
        end

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :help
          myHelp("group_conf")
          next
        end

        if ret == :next || ret == :back || ret == :wizardTree ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !group_conf_Write(old, cur)

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
