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
  module HeartbeatStonithConfInclude
    def initialize_heartbeat_stonith_conf(include_target)
      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "Heartbeat"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @xx = _("Specified STONITH host is already present.")
    end

    def ConfigureStonithDialog
      stonith = Ops.get_list(Heartbeat.config, "stonith_host", [])
      modified = false

      stonith = Builtins.maplist(stonith) do |s|
        l = Builtins.regexptokenize(s, "([^ \t]*)[ \t]*([^ \t]*)[ \t]*(.*)")
        Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(Ops.get_string(l, 0, ""), " "),
              Ops.get_string(l, 1, "")
            ),
            " "
          ),
          Ops.get_string(l, 2, "")
        )
      end

      run = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), "/usr/sbin/stonith -L")
      )
      devicetypes = Builtins.splitstring(
        Ops.get_string(run, "stdout", ""),
        "\n"
      )

      nodes = Builtins.add(Ops.get_list(Heartbeat.config, "node", []), "*")

      contents = VBox(
        VSquash(
          HBox(
            HWeight(
              9,
              Frame(
                _("Add STONITH Host"),
                HBox(
                  Left(
                    ComboBox(Id("host"), Opt(:editable), _("Host from"), nodes)
                  ),
                  HStretch(),
                  Left(
                    ComboBox(
                      Id("type"),
                      Opt(:editable),
                      _("STONITH Type"),
                      devicetypes
                    )
                  ),
                  HStretch(),
                  Left(TextEntry(Id("parameters"), _("Parameters")))
                )
              )
            ),
            HWeight(
              2,
              VBox(
                VSpacing(1),
                VSquash(PushButton(Id("add_stonith"), Label.AddButton)),
                VSpacing(0.5),
                VSquash(PushButton(Id("edit_stonith"), Label.EditButton)),
                VStretch()
              )
            )
          )
        ),
        HBox(
          HWeight(
            9,
            Table(
              Id("stonith_table"),
              Opt(:notify, :immediate),
              Header("Host From", "Type", "Parameters")
            )
          ),
          HWeight(
            2,
            VBox(
              VSpacing(1),
              VSquash(PushButton(Id("delete_stonith"), Label.DeleteButton)),
              VStretch()
            )
          )
        )
      )

      my_SetContents("stonith_conf", contents)

      UI.ChangeWidget(Id("host"), :Value, "*")

      ret = nil
      curid = nil
      while true
        istonith = Builtins.maplist(stonith) do |s|
          l = Builtins.regexptokenize(s, "([^ \t]*)[ \t]*([^ \t]*)[ \t]*(.*)")
          Item(
            Id(s),
            Ops.get_string(l, 0, ""),
            Ops.get_string(l, 1, ""),
            Ops.get_string(l, 2, "")
          )
        end
        UI.ChangeWidget(Id("stonith_table"), :Items, istonith)
        curid = nil if curid != nil && !Builtins.contains(stonith, curid)
        if curid != nil
          UI.ChangeWidget(Id("stonith_table"), :CurrentItem, curid)
        end

        UI.ChangeWidget(
          Id("delete_stonith"),
          :Enabled,
          Ops.greater_than(Builtins.size(istonith), 0)
        )
        UI.ChangeWidget(
          Id("edit_stonith"),
          :Enabled,
          Ops.greater_than(Builtins.size(istonith), 0)
        )

        selid = Convert.to_string(
          UI.QueryWidget(Id("stonith_table"), :CurrentItem)
        )
        if selid != nil
          l = Builtins.regexptokenize(
            selid,
            "([^ \t]*)[ \t]*([^ \t]*)[ \t]*(.*)"
          )
          UI.ChangeWidget(Id("host"), :Value, Ops.get_string(l, 0, ""))
          UI.ChangeWidget(Id("type"), :Value, Ops.get_string(l, 1, ""))
          UI.ChangeWidget(Id("parameters"), :Value, Ops.get_string(l, 2, ""))
        end

        ret = UI.UserInput

        if ret == :abort || ret == :cancel
          Ops.set(Heartbeat.config, "modified", true) if modified
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        break if ret == :next || ret == :back

        if ret == :help
          myHelp("stonith_conf")
          next
        end

        curid = Convert.to_string(
          UI.QueryWidget(Id("stonith_table"), :CurrentItem)
        )

        if ret == "stonith_table"
          if curid != nil
            l = Builtins.regexptokenize(
              curid,
              "([^ \t]*)[ \t]*([^ \t]*)[ \t]*(.*)"
            )
            UI.ChangeWidget(Id("host"), :Value, Ops.get_string(l, 0, ""))
            UI.ChangeWidget(Id("type"), :Value, Ops.get_string(l, 1, ""))
            UI.ChangeWidget(Id("parameters"), :Value, Ops.get_string(l, 2, ""))
          end
          next
        end

        if ret == "delete_stonith"
          stonith = Builtins.filter(stonith) { |s| s != curid } if curid != nil
          modified = true
          next
        end

        if ret == "add_stonith" || ret == "edit_stonith"
          host = Convert.to_string(UI.QueryWidget(Id("host"), :Value))
          type = Convert.to_string(UI.QueryWidget(Id("type"), :Value))
          param = Convert.to_string(UI.QueryWidget(Id("parameters"), :Value))
          if host == ""
            Report.Error(_("Specify the host name."))
            next
          end
          if type == ""
            Report.Error(_("Specify the STONITH type."))
            next
          end
          new = Ops.add(Ops.add(Ops.add(Ops.add(host, " "), type), " "), param)
          if ret == "edit_stonith"
            stonith = Builtins.filter(stonith) { |s| s != curid }
          elsif Builtins.contains(stonith, new)
            Report.Error(_("The specified STONITH is already present."))
            next
          end
          modified = true
          stonith = Builtins.filter(stonith) { |s| s != curid } if ret == "edit_stonith"
          curid = new
          stonith = Builtins.add(stonith, curid)
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

      if modified
        Ops.set(Heartbeat.config, "stonith_host", stonith)
        Ops.set(Heartbeat.config, "modified", true)
      end

      deep_copy(ret)
    end
  end
end
