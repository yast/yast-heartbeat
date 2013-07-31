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
  module HeartbeatNodeConfInclude
    def initialize_heartbeat_node_conf(include_target)
      Yast.import "UI"
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"
      Yast.import "Report"
      Yast.import "NetworkInterfaces"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @thisnode = ""
      @thisnodeip = ""
      @othernode = ""
    end

    def node_conf_Read
      nodes = Ops.get_list(Heartbeat.config, "node", [])

      unamemap = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "uname -n")
      )
      @thisnode = Builtins.deletechars(
        Ops.get_string(unamemap, "stdout", ""),
        "\n"
      )

      #read current settings for network
      NetworkInterfaces.Read

      #generate the map: static IP -> device
      devs = NetworkInterfaces.Locate("BOOTPROTO", "static")
      Builtins.foreach(devs) do |dev|
        ip = NetworkInterfaces.GetValue(dev, "IPADDR")
        @thisnodeip = ip if ip != nil && ip != ""
      end 

      #     foreach(string s, nodes, { if (s != thisnode) othernode = s; });

      nil
    end

    def node_conf_Write
      newnode = Convert.to_string(UI.QueryWidget(Id("othernode"), :Value))
      #     if (newnode == nil || newnode == "") {
      # 	Report::Error(_("The other node name is required."));
      # 	return false;
      #     }
      #     if (newnode == thisnode) {
      # 	Report::Error(_("The other node name cannot be same as this node name."));
      # 	return false;
      #     }

      #     list<string> onodes = Heartbeat::config["node"]:[];
      #     if (size(onodes) != 2 || onodes[0]:"" != thisnode || onodes[1]:"" != newnode) {
      # 	Heartbeat::config["node"] = nodes;
      # 	Heartbeat::config["modified"] = true;
      #     }

      true
    end

    def node_conf_getDialog
      VBox(
        HBox(
          HWeight(
            9,
            Frame(
              _("This Node"),
              HBox(
                Label(@thisnode),
                # 		          `HStretch(),
                Label("("),
                Label(@thisnodeip),
                Label(")")
              )
            )
          )
        ),
        VSquash(
          HBox(
            HWeight(
              9,
              Frame(
                _("Add Nodes"),
                HBox(
                  Left(
                    InputField(
                      Id("othernode"),
                      Opt(:hstretch),
                      _("Node Name"),
                      @othernode
                    )
                  )
                )
              )
            ),
            HWeight(
              2,
              VBox(
                VSpacing(1),
                VSquash(PushButton(Id("add_node"), Label.AddButton)),
                VSpacing(0.5),
                VSquash(PushButton(Id("edit_node"), Label.EditButton)),
                VStretch()
              )
            )
          )
        ),
        HBox(
          HWeight(
            9,
            Table(
              Id("node_table"),
              Opt(:notify, :immediate),
              Header(_("Node Name"))
            )
          ),
          HWeight(
            2,
            VBox(
              VSpacing(1),
              VSquash(PushButton(Id("delete_node"), Label.DeleteButton)),
              VStretch()
            )
          )
        )
      )
    end

    def ConfigureNodeDialog
      node_conf_Read

      my_SetContents("node_conf", node_conf_getDialog)

      nodes = Ops.get_list(Heartbeat.config, "node", [])
      nodes = Builtins.filter(nodes) { |s| s != @thisnode }
      modified = false

      ret = nil
      curnode = nil
      while true
        inodes = Builtins.maplist(nodes) { |s| Item(Id(s), s) }
        UI.ChangeWidget(Id("node_table"), :Items, inodes)
        curnode = nil if curnode != nil && !Builtins.contains(nodes, curnode)
        if curnode != nil
          UI.ChangeWidget(Id("node_table"), :CurrentItem, curnode)
        end

        UI.ChangeWidget(
          Id("delete_node"),
          :Enabled,
          Ops.greater_than(Builtins.size(inodes), 0)
        )
        UI.ChangeWidget(
          Id("edit_node"),
          :Enabled,
          Ops.greater_than(Builtins.size(inodes), 0)
        )

        Wizard.SelectTreeItem("node_conf")

        selnode = Convert.to_string(
          UI.QueryWidget(Id("node_table"), :CurrentItem)
        )
        UI.ChangeWidget(Id("othernode"), :Value, selnode) if selnode != nil

        ret = UI.UserInput

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :help
          myHelp("node_conf")
          next
        end

        curnode = Convert.to_string(
          UI.QueryWidget(Id("node_table"), :CurrentItem)
        )

        if ret == "node_table"
          UI.ChangeWidget(Id("othernode"), :Value, curnode) if curnode != nil
          next
        end

        if ret == "delete_node"
          nodes = Builtins.filter(nodes) { |s| s != curnode } if curnode != nil
          modified = true
          next
        end

        if ret == "add_node" || ret == "edit_node"
          nodename = Convert.to_string(UI.QueryWidget(Id("othernode"), :Value))
          if nodename == ""
            Report.Error(_("Specify the node name."))
            next
          end
          if nodename == @thisnode
            Report.Error(_("The specified node is already in the cluster."))
            next
          end
          new = nodename
          if ret == "edit_node"
            nodes = Builtins.filter(nodes) { |s| s != curnode }
          elsif Builtins.contains(nodes, new)
            Report.Error(_("The specified node is already in the cluster."))
            next
          end
          modified = true
          nodes = Builtins.filter(nodes) { |s| s != curnode } if ret == "edit_node"
          curnode = new
          nodes = Builtins.add(nodes, curnode)
          next
        end

        if ret == :wizardTree
          ret = Convert.to_string(UI.QueryWidget(Id(:wizardTree), :CurrentItem))
        end

        if ret == :next || ret == :back ||
            Builtins.contains(@DIALOG, Convert.to_string(ret))
          # 	    if (!node_conf_Write()) continue;

          if ret != :next && ret != :back
            ret = Builtins.symbolof(Builtins.toterm(ret))
          end

          break
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end

      if modified
        nodes = Builtins.add(nodes, @thisnode)
        Ops.set(Heartbeat.config, "node", nodes)
        Ops.set(Heartbeat.config, "modified", true)
      end

      deep_copy(ret)
    end
  end
end
