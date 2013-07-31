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
  module HeartbeatResourcesConfInclude
    def initialize_heartbeat_resources_conf(include_target)
      Yast.import "UI"

      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"
      Yast.import "Report"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @nodes = []
    end

    def res_Read
      r = {}

      @nodes = Ops.get_list(Heartbeat.config, "node", [])

      auto_failback = Builtins.tolower(
        Ops.get_string(Heartbeat.config, "auto_failback", "legacy")
      )
      if auto_failback == "on" || auto_failback == "1" || auto_failback == "y" ||
          auto_failback == "yes" ||
          auto_failback == "true"
        auto_failback = "on"
      elsif auto_failback == "off" || auto_failback == "0" ||
          auto_failback == "n" ||
          auto_failback == "no" ||
          auto_failback == "false"
        auto_failback = "off"
      else
        auto_failback = "legacy"
      end
      Ops.set(r, "auto_failback", auto_failback)

      Ops.set(
        r,
        "resources",
        [
          Ops.get_list(Heartbeat.resources, Ops.get(@nodes, 0, ""), []),
          Ops.get_list(Heartbeat.resources, Ops.get(@nodes, 1, ""), [])
        ]
      )

      deep_copy(r)
    end

    def res_Write(old, new)
      old = deep_copy(old)
      new = deep_copy(new)
      Builtins.foreach([0, 1]) do |n|
        if !cmpList(
            Ops.get_list(old, ["resources", n], []),
            Ops.get_list(new, ["resources", n], [])
          )
          Heartbeat.resources_modified = true
          node = Ops.get(@nodes, n, "")
          Ops.set(
            Heartbeat.resources,
            node,
            Ops.get_list(new, ["resources", n], [])
          )
        end
      end

      if Ops.get_string(old, "auto_failback", "") !=
          Ops.get_string(new, "auto_failback", "")
        Ops.set(Heartbeat.config, "modified", true)
        Ops.set(
          Heartbeat.config,
          "auto_failback",
          Builtins.tolower(Ops.get_string(new, "auto_failback", "legacy"))
        )
      end

      true
    end

    def res_getSelIndex(r, n)
      r = deep_copy(r)
      sel = Convert.to_string(
        UI.QueryWidget(Id(Ops.add("node", Builtins.tostring(n))), :CurrentItem)
      )

      i = Builtins.size(Ops.get_list(r, ["resources", n], []))
      while Ops.greater_or_equal(i, 0)
        return i if sel == Ops.get_string(r, ["resources", n, i], "")
        i = Ops.subtract(i, 1)
      end

      -1
    end


    def res_updateOrder(cur, n)
      cur = deep_copy(cur)
      i = res_getSelIndex(cur, n)
      r = Ops.get_list(cur, ["resources", n], [])

      return 0 if Ops.less_than(i, 0)

      UI.ChangeWidget(
        Id(Ops.add("up", Builtins.tostring(n))),
        :Enabled,
        Ops.greater_than(i, 0)
      )
      UI.ChangeWidget(
        Id(Ops.add("down", Builtins.tostring(n))),
        :Enabled,
        Ops.less_than(i, Ops.subtract(Builtins.size(r), 1))
      )

      nil
    end

    def res_updateList(r, n, sel)
      r = deep_copy(r)
      nid = Ops.add("node", Builtins.tostring(n))
      UI.ReplaceWidget(
        Id(Ops.add(nid, "_rp")),
        SelectionBox(
          Id(nid),
          Opt(:notify, :autoShortcut),
          Ops.get(@nodes, n, nid),
          Ops.get_list(r, ["resources", n], [])
        )
      )

      if sel != "" && sel != nil &&
          Builtins.contains(Ops.get_list(r, ["resources", n], []), sel)
        UI.ChangeWidget(Id(nid), :CurrentItem, sel)
      end

      res_updateOrder(r, n)

      nil
    end


    def res_SetDialog(r)
      r = deep_copy(r)
      nodes = Ops.get_list(Heartbeat.config, "node", [])
      i = -1
      inodes = Builtins.maplist(nodes) do |s|
        i = Ops.add(i, 1)
        Item(
          Id(Ops.add(Ops.add("node", Builtins.tostring(i)), "_sel")),
          Ops.get(nodes, i, "")
        )
      end

      _TAutoFailback = HBox(
        Left(
          ComboBox(
            Id("auto_failback"),
            _("Automatic Failback"),
            ["On", "Off", "Legacy"]
          )
        )
      )
      _TAddResources = HBox(
        HWeight(
          9,
          Bottom(
            Frame(
              _("Add Resource"),
              HBox(
                ComboBox(Id("add_to_node"), _("Add to Node"), inodes),
                HSpacing(1),
                TextEntry(Id("resource"), _("Resource"))
              )
            )
          )
        ),
        HWeight(
          2,
          Bottom(
            PushButton(Id("add_resource"), Opt(:hstretch), Label.AddButton)
          )
        )
      )

      _TList = HBox(
        HBox(
          ReplacePoint(Id("node0_rp"), Empty()),
          HSquash(
            VBox(
              VStretch(),
              PushButton(Id("delete0"), Opt(:hstretch), Label.DeleteButton),
              VSpacing(1),
              PushButton(Id("up0"), Opt(:hstretch), Label.UpButton),
              VSpacing(1),
              PushButton(Id("down0"), Opt(:hstretch), Label.DownButton)
            )
          )
        ),
        HSpacing(1),
        HBox(
          ReplacePoint(Id("node1_rp"), Empty()),
          HSquash(
            VBox(
              VStretch(),
              PushButton(Id("delete1"), Opt(:hstretch), Label.DeleteButton),
              VSpacing(1),
              PushButton(Id("up1"), Opt(:hstretch), Label.UpButton),
              VSpacing(1),
              PushButton(Id("down1"), Opt(:hstretch), Label.DownButton)
            )
          )
        )
      )

      contents = VBox(
        VSquash(_TAutoFailback),
        VSpacing(0.5),
        VSquash(_TAddResources),
        VSpacing(0.5),
        _TList
      )

      my_SetContents("resources_conf", contents)

      if Ops.get_string(r, "auto_failback", "") == "legacy"
        UI.ChangeWidget(Id("auto_failback"), :Value, "Legacy")
      elsif Ops.get_string(r, "auto_failback", "") == "on"
        UI.ChangeWidget(Id("auto_failback"), :Value, "On")
      else
        UI.ChangeWidget(Id("auto_failback"), :Value, "Off")
      end

      res_updateList(r, 0, Ops.get_string(r, ["resources", 0, 0], ""))
      res_updateList(r, 1, Ops.get_string(r, ["resources", 1, 0], ""))

      nil
    end

    def res_UpdateDialog(r)
      r = deep_copy(r)
      Builtins.foreach([0, 1]) do |n|
        enab = Ops.greater_than(
          Builtins.size(Ops.get_list(r, ["resources", n], [])),
          0
        )
        UI.ChangeWidget(
          Id(Ops.add("delete", Builtins.tostring(n))),
          :Enabled,
          enab
        )
        if enab
          res_updateOrder(r, n)
        else
          UI.ChangeWidget(
            Id(Ops.add("up", Builtins.tostring(n))),
            :Enabled,
            enab
          )
          UI.ChangeWidget(
            Id(Ops.add("down", Builtins.tostring(n))),
            :Enabled,
            enab
          )
        end
      end

      nil
    end

    def res_Current(old)
      old = deep_copy(old)
      new = deep_copy(old)
      Ops.set(
        new,
        "auto_failback",
        Builtins.tolower(
          Convert.to_string(UI.QueryWidget(Id("auto_failback"), :Value))
        )
      )
      deep_copy(new)
    end

    def res_delete(cur, n)
      cur = deep_copy(cur)
      sel = Convert.to_string(
        UI.QueryWidget(Id(Ops.add("node", Builtins.tostring(n))), :CurrentItem)
      )
      Ops.set(
        cur,
        ["resources", n],
        Builtins.filter(Ops.get_list(cur, ["resources", n], [])) { |s| s != sel }
      )
      deep_copy(cur)
    end


    def res_updown(cur, n, direction)
      cur = deep_copy(cur)
      i = res_getSelIndex(cur, n)
      r = Ops.get_list(cur, ["resources", n], [])
      sel = Ops.get_string(r, i, "")
      Builtins.y2milestone("sel %1 %2", i, sel)

      return deep_copy(cur) if Ops.less_than(i, 0)

      if direction == "up" && Ops.greater_than(i, 0)
        nr = []
        while Ops.greater_than(i, 1)
          nr = Builtins.add(nr, Ops.get_string(r, 0, ""))
          r = Builtins.remove(r, 0)
          i = Ops.subtract(i, 1)
        end
        nr = Builtins.add(nr, Ops.get_string(r, 1, ""))
        nr = Builtins.merge(nr, Builtins.remove(r, 1))
        Ops.set(cur, ["resources", n], nr)
        res_updateList(cur, n, sel)
      elsif direction == "down" &&
          Ops.less_than(i, Ops.subtract(Builtins.size(r), 1))
        nr = []
        while Ops.greater_than(i, 0)
          nr = Builtins.add(nr, Ops.get_string(r, 0, ""))
          r = Builtins.remove(r, 0)
          i = Ops.subtract(i, 1)
        end
        nr = Builtins.add(nr, Ops.get_string(r, 1, ""))
        nr = Builtins.merge(nr, Builtins.remove(r, 1))
        Ops.set(cur, ["resources", n], nr)
        res_updateList(cur, n, sel)
      end

      deep_copy(cur)
    end

    def ConfigureResourcesDialog
      nodes = Ops.get_list(Heartbeat.config, "node", [])
      if Builtins.size(nodes) != 2
        Report.Error(
          _("Heartbeat resource manager only supports two nodes.") + " " +
            _("Configure nodes first.")
        )
        return :node_conf
      end

      old = res_Read
      cur = deep_copy(old)

      res_SetDialog(old)

      ret = nil
      while true
        Wizard.SelectTreeItem("resources_conf")

        res_UpdateDialog(cur)

        ret = UI.UserInput

        cur = res_Current(cur)

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
          next if !res_Write(old, cur)

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

        if ret == "add_resource"
          res = Convert.to_string(UI.QueryWidget(Id("resource"), :Value))
          node = Convert.to_string(UI.QueryWidget(Id("add_to_node"), :Value))
          n = Builtins.tointeger(Builtins.filterchars(node, "0123456789"))

          if res == nil || res == ""
            Report.Error(_("Resource name is required."))
          elsif Builtins.contains(Ops.get_list(cur, ["resources", n], []), res)
            Report.Error(_("The specified resource is already present."))
          else
            Ops.set(
              cur,
              ["resources", n],
              Builtins.add(Ops.get_list(cur, ["resources", n], []), res)
            )
            res_updateList(cur, n, res)
          end
          next
        end

        if ret == "delete0"
          cur = res_delete(cur, 0)
          res_updateList(cur, 0, Ops.get_string(cur, ["resources", 0, 0], ""))
          next
        end

        if ret == "delete1"
          cur = res_delete(cur, 1)
          res_updateList(cur, 1, Ops.get_string(cur, ["resources", 1, 0], ""))
          next
        end

        if ret == "up0"
          cur = res_updown(cur, 0, "up")
          next
        end
        if ret == "up1"
          cur = res_updown(cur, 1, "up")
          next
        end
        if ret == "down0"
          cur = res_updown(cur, 0, "down")
          next
        end
        if ret == "down1"
          cur = res_updown(cur, 1, "down")
          next
        end

        if ret == "node0"
          res_updateOrder(cur, 0)
          next
        end
        if ret == "node1"
          res_updateOrder(cur, 1)
          next
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end


      deep_copy(ret)
    end
  end
end
