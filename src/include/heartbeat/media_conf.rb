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
  module HeartbeatMediaConfInclude
    def initialize_heartbeat_media_conf(include_target)
      Yast.import "UI"

      textdomain "heartbeat"

      Yast.import "Label"
      Yast.import "FileUtils"
      Yast.import "Report"
      Yast.import "Wizard"
      Yast.import "Heartbeat"
      Yast.import "IP"
      Yast.import "NetworkInterfaces"

      Yast.include include_target, "heartbeat/helps.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @media_warned = false
    end

    def media_Read
      media = {}
      #     media["serial"] = Heartbeat::config["serial"]:[];
      Ops.set(media, "bcast", Ops.get_list(Heartbeat.config, "bcast", []))
      #     media["ucast"] = Heartbeat::config["ucast"]:[];
      Ops.set(media, "mcast", Ops.get_list(Heartbeat.config, "mcast", []))

      Ops.set(
        media,
        "udpport",
        Ops.get_string(Heartbeat.config, "udpport", "694")
      )
      #     media["baud"] = Heartbeat::config["baud"]:"57600";

      deep_copy(media)
    end

    def media_Write(old, new, exitdir)
      old = deep_copy(old)
      new = deep_copy(new)
      exitdir = deep_copy(exitdir)
      if !@media_warned && exitdir != :back
        siz = 0
        Builtins.foreach(["serial", "bcast", "mcast", "ucast"]) do |key|
          siz = Ops.add(siz, Builtins.size(Ops.get_list(new, key, [])))
        end
        if Ops.less_than(siz, 2)
          if !Popup.ContinueCancel(
              _(
                "Warning: No redundancy in the Heartbeat communication channels.\n" +
                  "Multiple media should be configured to reduce the likelihood of\n" +
                  "critical split brain scenarios.\n"
              )
            )
            return false
          end
          @media_warned = true
        end
      end

      Builtins.foreach(["serial", "bcast", "mcast", "ucast"]) do |cast|
        same = true
        if Builtins.size(Ops.get_list(old, cast, [])) !=
            Builtins.size(Ops.get_list(new, cast, []))
          same = false
        else
          i = Builtins.size(Ops.get_list(old, cast, []))
          while Ops.greater_or_equal(i, 0) &&
              Ops.get_string(old, [cast, i], "") ==
                Ops.get_string(new, [cast, i], "")
            i = Ops.subtract(i, 1)
          end
          same = false if Ops.greater_or_equal(i, 0)
        end
        if !same
          Ops.set(Heartbeat.config, "modified", true)
          Ops.set(Heartbeat.config, cast, Ops.get_list(new, cast, []))
        end
      end

      ha_cf = Ops.add(Ops.add(Heartbeat.ha_dir, "/"), "ha.cf")

      #foreach(string x, ["udpport", "baud"], {
      Builtins.foreach(["udpport"]) do |x|
        if Ops.get_string(old, x, "") != Ops.get_string(new, x, "") ||
            !FileUtils.Exists(ha_cf)
          #set as modified also if ha.cf does not exist yet
          #so the data get written (#235834)
          Ops.set(Heartbeat.config, "modified", true)
          Ops.set(Heartbeat.config, x, Ops.get_string(new, x, ""))
        end
      end

      true
    end

    def media_updateList(media, sel)
      media = deep_copy(media)
      imedia = []
      Builtins.foreach(["serial", "bcast", "mcast", "ucast"]) do |key|
        val = Ops.get_list(media, key, [])
        index = -1
        im = Builtins.maplist(
          Convert.convert(val, :from => "list", :to => "list <string>")
        ) do |s|
          index = Ops.add(index, 1)
          Item(
            Id(
              Ops.add(Ops.add(Ops.add(key, "["), Builtins.tostring(index)), "]")
            ),
            key,
            Ops.get_string(val, index, "")
          )
        end
        imedia = Builtins.union(imedia, im)
      end

      UI.ChangeWidget(Id("configured_media_table"), :Items, imedia)

      if Ops.greater_than(Builtins.size(imedia), 0) && sel != nil && sel != ""
        UI.ChangeWidget(Id("configured_media_table"), :CurrentItem, sel)
      end

      nil
    end

    def media_syncEdits(cur)
      cur = deep_copy(cur)
      curid = Convert.to_string(
        UI.QueryWidget(Id("configured_media_table"), :CurrentItem)
      )
      l = Builtins.regexptokenize(curid, "([a-z]*).([0-9]*)")
      i = Builtins.tointeger(Ops.get_string(l, 1, "0"))
      UI.ChangeWidget(
        Id("media_type"),
        :CurrentButton,
        Ops.add("media_type_", Ops.get_string(l, 0, "mcast"))
      )
      if Ops.get_string(l, 0, "") == "bcast"
        UI.ChangeWidget(
          Id("bcast_device"),
          :Value,
          Ops.get_string(cur, ["bcast", i], "")
        )
      elsif Ops.get_string(l, 0, "") == "mcast"
        m = Builtins.splitstring(Ops.get_string(cur, ["mcast", i], ""), " \t")
        UI.ChangeWidget(Id("mcast_device"), :Value, Ops.get_string(m, 0, ""))
        UI.ChangeWidget(Id("mcast_address"), :Value, Ops.get_string(m, 1, ""))
        UI.ChangeWidget(
          Id("ttl"),
          :Value,
          Builtins.tointeger(Ops.get_string(m, 3, ""))
        )
      end

      nil
    end

    def media_SetDialog(media)
      media = deep_copy(media)
      serial_ports = ["/dev/ttyS0", "/dev/ttyS1", "/dev/ttyS2"]
      rates = ["19200", "38400", "57600", "115200"]

      NetworkInterfaces.Read
      devs = NetworkInterfaces.List("eth")
      net_devices = []
      Builtins.foreach(devs) do |dev|
        ifcfg = Ops.add("getcfg-interface ", dev)
        devmap = Convert.to_map(SCR.Execute(path(".target.bash_output"), ifcfg))
        tdev = Builtins.deletechars(Ops.get_string(devmap, "stdout", ""), "\n")
        net_devices = Builtins.add(net_devices, tdev)
      end

      _TPort = HBox(
        HSquash(
          Left(
            InputField(
              Id("udpport"),
              _("UDP Port"),
              Ops.get_string(media, "udpport", "694")
            )
          )
        ),
        HSpacing(2),
        # 	`HSquash(`Left(`ComboBox(`id("baud"), `opt(`editable), _("Baud Rate"), rates))),
        HStretch()
      )

      _TRadio = RadioButtonGroup(
        Id("media_type"),
        VBox(
          #         `Left(`HBox(
          # 	    `RadioButton( `id ("media_type_serial"), `opt(`notify), _("Serial Port"), true),
          # 	    `HSpacing(2),
          # 	    `ComboBox(`id("serial_port"), `opt(`editable), _("Serial Port Name"), serial_ports))),
          Left(
            HBox(
              RadioButton(
                Id("media_type_bcast"),
                Opt(:notify),
                _("Broadcast"),
                false
              ),
              HSpacing(2),
              ComboBox(
                Id("bcast_device"),
                Opt(:editable),
                _("Device"),
                net_devices
              )
            )
          ),
          # 	`Left(`HBox(
          # 	    `RadioButton(`id("media_type_ucast"), `opt(`notify), _("Unicast"), false),
          # 	    `HSpacing(2),
          # 	    `TextEntry(`id("ucast_address"), _("IP Address"), "" ),
          # 	    `HSpacing(1),
          # 	    `ComboBox(`id("ucast_device"), `opt(`editable), _("Device"), net_devices))),
          Left(
            HBox(
              RadioButton(
                Id("media_type_mcast"),
                Opt(:notify),
                _("Multicast"),
                false
              ),
              HSpacing(2),
              InputField(
                Id("mcast_address"),
                Opt(:hstretch),
                _("Multicast Group"),
                ""
              ),
              HSpacing(1),
              ComboBox(
                Id("mcast_device"),
                Opt(:editable),
                _("Device"),
                net_devices
              ),
              HSpacing(1),
              IntField(Id("ttl"), _("TTL"), 1, 255, 2),
              HStretch()
            )
          )
        )
      )

      _TAdd = VSquash(
        HBox(
          HWeight(9, Frame(_("Heartbeat Medium"), _TRadio)),
          HWeight(
            2,
            VBox(
              VStretch(),
              PushButton(Id("add_media"), Opt(:hstretch), Label.AddButton),
              VSpacing(1),
              PushButton(Id("edit_media"), Opt(:hstretch), Label.EditButton)
            )
          )
        )
      )

      _TList = HBox(
        HWeight(
          9,
          Table(
            Id("configured_media_table"),
            Opt(:notify, :immediate),
            Header(_("Medium"), _("Options"))
          )
        ),
        HWeight(
          2,
          VBox(
            VSpacing(1),
            PushButton(Id("delete_media"), Opt(:hstretch), Label.DeleteButton),
            VStretch()
          )
        )
      )

      contents = VBox(_TAdd, VSpacing(0.5), _TList, _TPort)

      my_SetContents("media_conf", contents)

      UI.ChangeWidget(Id("udpport"), :ValidChars, "0123456789")
      #     UI::ChangeWidget(`id("baud"), `ValidChars, "0123456789");
      #     UI::ChangeWidget(`id("baud"), `Value, media["baud"]:"57600");

      media_updateList(media, nil)

      nil
    end

    def media_UpdateDialog(media)
      media = deep_copy(media)
      media_non_empty = Ops.greater_than(
        Builtins.size(Ops.get_list(media, "bcast", [])),
        0
      ) ||
        Ops.greater_than(Builtins.size(Ops.get_list(media, "mcast", [])), 0) ||
        Ops.greater_than(Builtins.size(Ops.get_list(media, "serial", [])), 0) ||
        Ops.greater_than(Builtins.size(Ops.get_list(media, "ucast", [])), 0)

      UI.ChangeWidget(Id("delete_media"), :Enabled, media_non_empty)
      UI.ChangeWidget(Id("edit_media"), :Enabled, media_non_empty)

      type = Convert.to_string(UI.QueryWidget(Id("media_type"), :CurrentButton))

      #     UI::ChangeWidget(`id("serial_port"), `Enabled, type == "media_type_serial");

      UI.ChangeWidget(Id("bcast_device"), :Enabled, type == "media_type_bcast")

      #     UI::ChangeWidget(`id("ucast_device"), `Enabled, type == "media_type_ucast");
      #     UI::ChangeWidget(`id("ucast_address"), `Enabled, type == "media_type_ucast");

      UI.ChangeWidget(Id("mcast_device"), :Enabled, type == "media_type_mcast")
      UI.ChangeWidget(Id("mcast_address"), :Enabled, type == "media_type_mcast")
      UI.ChangeWidget(Id("ttl"), :Enabled, type == "media_type_mcast")

      nil
    end

    def media_Current(old)
      old = deep_copy(old)
      new = deep_copy(old)

      Ops.set(
        new,
        "udpport",
        Convert.to_string(UI.QueryWidget(Id("udpport"), :Value))
      )
      #     new["baud"] = (string)UI::QueryWidget(`id("baud"), `Value);
      deep_copy(new)
    end

    def media_already
      Report.Error(_("Specified media is already present."))

      nil
    end

    def media_delete(cur, edit)
      cur = deep_copy(cur)
      curid = Convert.to_string(
        UI.QueryWidget(Id("configured_media_table"), :CurrentItem)
      )
      l = Builtins.regexptokenize(curid, "([a-z]*).([0-9]*)")
      i = Builtins.tointeger(Ops.get_string(l, 1, "0"))
      medname = Ops.get_string(l, 0, "")
      Ops.set(cur, medname, Builtins.remove(Ops.get_list(cur, medname, []), i))

      media_updateList(cur, nil) if !edit

      deep_copy(cur)
    end

    def media_add(cur, edit)
      cur = deep_copy(cur)
      mn = Convert.to_string(UI.QueryWidget(Id("media_type"), :CurrentButton))
      all = ""
      #     if (mn=="media_type_serial") {
      # 	all = (string)UI::QueryWidget(`id("serial_port"), `Value);
      # 	if (!edit && contains(cur["serial"]:[], all)) {
      # 	    media_already();
      # 	    return cur;
      # 	}
      # 	cur["serial"] = add(cur["serial"]:[], all);
      #     } else
      if mn == "media_type_bcast"
        all = Convert.to_string(UI.QueryWidget(Id("bcast_device"), :Value))
        if !edit && Builtins.contains(Ops.get_list(cur, "bcast", []), all)
          media_already
          return deep_copy(cur)
        end
        Ops.set(cur, "bcast", Builtins.add(Ops.get_list(cur, "bcast", []), all)) 
        #     } else if (mn=="media_type_ucast") {
        # 	string dev = (string)UI::QueryWidget(`id("ucast_device"), `Value);
        # 	string address = (string)UI::QueryWidget(`id("ucast_address"), `Value);
        # 	if (! IP::Check4(address)) {
        # 	    Report::Error (IP::Valid4 ());
        # 	    return cur;
        # 	}
        # 	string all = dev + " " + address;
        # 	if (!edit && contains(cur["ucast"]:[], all)) {
        # 	    media_already();
        # 	    return cur;
        # 	}
        # 	cur["ucast"] = add(cur["ucast"]:[], all);
      elsif mn == "media_type_mcast"
        dev = Convert.to_string(UI.QueryWidget(Id("mcast_device"), :Value))
        address = Convert.to_string(UI.QueryWidget(Id("mcast_address"), :Value))
        ttl = Convert.to_integer(UI.QueryWidget(Id("ttl"), :Value))
        if !IP.Check4(address)
          Report.Error(IP.Valid4)
          return deep_copy(cur)
        end
        ip = Builtins.splitstring(address, ".")
        ip1 = Builtins.tointeger(Ops.get_string(ip, 0, "224"))
        if Ops.less_than(ip1, 224) || Ops.greater_than(ip1, 239)
          Report.Error(
            _(
              "Multicast group address must be class D (224.0.0.0 - 239.255.255.255)."
            )
          )
          return deep_copy(cur)
        end
        all2 = Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(
                Ops.add(Ops.add(Ops.add(dev, " "), address), " "),
                Ops.get_string(cur, "udpport", "694")
              ),
              " "
            ),
            Builtins.tostring(ttl)
          ),
          " 0"
        )
        if !edit && Builtins.contains(Ops.get_list(cur, "mcast", []), all2)
          media_already
          return deep_copy(cur)
        end
        Ops.set(
          cur,
          "mcast",
          Builtins.add(Ops.get_list(cur, "mcast", []), all2)
        )
      end

      media_updateList(cur, nil)
      deep_copy(cur)
    end

    def ConfigureMediaDialog
      old = media_Read
      cur = deep_copy(old)

      media_SetDialog(old)

      ret = nil
      while true
        Wizard.SelectTreeItem("media_conf")

        curradio = Convert.to_string(
          UI.QueryWidget(Id("media_type"), :CurrentButton)
        )
        if curradio != "media_type_bcast" && curradio != "media_type_mcast"
          media_syncEdits(cur)
        end
        media_UpdateDialog(cur)

        ret = UI.UserInput

        cur = media_Current(cur)

        if ret == :abort || ret == :cancel
          if ReallyAbort()
            return deep_copy(ret)
          else
            next
          end
        end

        if ret == :help
          myHelp("media_conf")
          next
        end

        if ret == :next || ret == :back || ret == :wizardTree ||
            Builtins.contains(@DIALOG, Builtins.tostring(ret))
          next if !media_Write(old, cur, ret)

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

        if ret == "media_type_serial" || ret == "media_type_bcast" ||
            ret == "media_type_ucast" ||
            ret == "media_type_mcast"
          next
        end

        if ret == "configured_media_table"
          media_syncEdits(cur)
          next
        end

        if ret == "delete_media"
          cur = media_delete(cur, false)
          next
        end

        if ret == "add_media"
          cur = media_add(cur, false)
          next
        end

        if ret == "edit_media"
          cur = media_delete(cur, true)
          cur = media_add(cur, true)
          next
        end

        Builtins.y2error("unexpected retcode: %1", ret)
      end

      deep_copy(ret)
    end
  end
end
