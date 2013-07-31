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
# File:	include/heartbeat/commandline.ycp
# Package:	Configuration of HA
# Summary:	Command line handlers
# Authors:	Ladislav Slezak <lslezak@novell.com>
#
# $Id$
module Yast
  module HeartbeatCommandlineInclude
    def initialize_heartbeat_commandline(include_target)
      Yast.import "Heartbeat"
      Yast.import "CommandLine"

      textdomain "heartbeat"

      # default values
      @default_udp_port = 694
      @default_udp_port_str = Builtins.tostring(@default_udp_port)

      @default_ttl = 2
      @default_ttl_str = Builtins.tostring(@default_ttl)
    end

    # Command line handler for List action: list available configurations
    def ListNodes
      nodes = Ops.get_list(Heartbeat.config, "node", [])
      Builtins.foreach(nodes) { |node| CommandLine.Print(node) } 


      false # = do not try to write
    end

    # Command line handler for List action: list available configurations
    def AddNode(name)
      nodes = Ops.get_list(Heartbeat.config, "node", [])

      if name != "" && !Builtins.contains(nodes, name)
        # add the specified node
        nodes = Builtins.add(nodes, name)
        Ops.set(Heartbeat.config, "node", nodes)
        Ops.set(Heartbeat.config, "modified", true)

        # command line status message, %1 is name of the node
        CommandLine.PrintVerbose(Builtins.sformat(_("Added node '%1'"), name))

        Builtins.y2debug("New config: %1", Heartbeat.config)
        return true
      end

      false # = do not try to write
    end

    def DeleteNode(name)
      nodes = Ops.get_list(Heartbeat.config, "node", [])

      if name != "" && Builtins.contains(nodes, name)
        # remove the specified node
        nodes = Builtins.filter(nodes) { |node| node != name }
        Ops.set(Heartbeat.config, "node", nodes)
        Ops.set(Heartbeat.config, "modified", true)

        # command line status message, %1 is name of the node
        CommandLine.PrintVerbose(Builtins.sformat(_("Removed node '%1'"), name))

        Builtins.y2debug("New config: %1", Heartbeat.config)
        return true
      end

      false # = do not try to write
    end


    # Command line handler for List action: list available configurations
    def NodeHandler(params)
      params = deep_copy(params)
      return ListNodes() if Builtins.haskey(params, "list")

      name = Ops.get_string(params, "name", "")

      if name != ""
        if Builtins.haskey(params, "add")
          return AddNode(name)
        elsif Builtins.haskey(params, "delete")
          return DeleteNode(name)
        end
      else
        CommandLine.Print("ERROR: Missing or empty 'name' option!")
      end

      false
    end

    def ListMedia
      bcast = Ops.get_list(Heartbeat.config, "bcast", [])
      mcast = Ops.get_list(Heartbeat.config, "mcast", [])

      Builtins.foreach(bcast) do |d|
        CommandLine.Print(Builtins.sformat(_("Broadcast device: %1"), d))
      end 


      Builtins.foreach(mcast) do |d|
        options = Builtins.splitstring(d, " ")
        options = Builtins.filter(options) { |optn| optn != nil && optn != "" }
        CommandLine.Print(
          Builtins.sformat(
            _("Multicast device: %1, address: %2, UDP: %3, TTL: %4"),
            Ops.get(options, 0, ""),
            Ops.get(options, 1, ""),
            Ops.get(options, 2, ""),
            Ops.get(options, 3, "")
          )
        )
      end 


      false
    end

    def GetUDP
      udpport = Ops.get_string(
        Heartbeat.config,
        "udpport",
        @default_udp_port_str
      )
      CommandLine.Print(udpport)
      false
    end

    def SetUDP(udpport)
      current_udpport = Ops.get_string(
        Heartbeat.config,
        "udpport",
        @default_udp_port_str
      )
      udpport_str = Builtins.tostring(udpport)

      if udpport_str != current_udpport
        CommandLine.PrintVerbose(
          Builtins.sformat(_("Setting UDP port to %1"), udpport_str)
        )
        Ops.set(Heartbeat.config, "modified", true)
        Ops.set(Heartbeat.config, "udpport", udpport_str)
        return true
      end

      false
    end

    def MCastDeviceString(device, address, ttl, udp)
      Ops.add(
        Ops.add(
          Ops.add(
            Ops.add(
              Ops.add(Ops.add(Ops.add(device, " "), address), " "),
              Builtins.tostring(udp)
            ),
            " "
          ),
          Builtins.tostring(ttl)
        ),
        " 0"
      )
    end

    def AddMedium(type, device, address, ttl, udp)
      if type == "bcast"
        bcast_devices = Ops.get_list(Heartbeat.config, "bcast", [])

        if !Builtins.contains(bcast_devices, device)
          Ops.set(Heartbeat.config, "modified", true)
          Ops.set(
            Heartbeat.config,
            "bcast",
            Builtins.add(bcast_devices, device)
          )
          return true
        end
      elsif type == "mcast"
        medium = MCastDeviceString(device, address, ttl, udp)
        mcast_devices = Ops.get_list(Heartbeat.config, "bcast", [])

        if !Builtins.contains(mcast_devices, medium)
          Ops.set(Heartbeat.config, "modified", true)
          Ops.set(
            Heartbeat.config,
            "mcast",
            Builtins.add(mcast_devices, medium)
          )
          return true
        end
      end

      false
    end

    def DeleteMedium(type, device, address, ttl, udp)
      if type == "bcast"
        bcast_devices = Ops.get_list(Heartbeat.config, "bcast", [])

        if Builtins.contains(bcast_devices, device)
          Ops.set(Heartbeat.config, "modified", true)
          Ops.set(Heartbeat.config, "bcast", Builtins.filter(bcast_devices) do |dev|
            dev != device
          end)
          return true
        end
      elsif type == "mcast"
        medium = MCastDeviceString(device, address, ttl, udp)
        mcast_devices = Ops.get_list(Heartbeat.config, "mcast", [])

        if Builtins.contains(mcast_devices, medium)
          Ops.set(Heartbeat.config, "modified", true)
          Ops.set(Heartbeat.config, "mcast", Builtins.filter(mcast_devices) do |dev|
            dev != medium
          end)
          return true
        end
      end

      false
    end

    # Command line handler for List action: list available configurations
    def MediumHandler(params)
      params = deep_copy(params)
      return ListMedia() if Builtins.haskey(params, "list")

      if Builtins.haskey(params, "set")
        if Builtins.haskey(params, "udp")
          udp2 = Builtins.tointeger(
            Ops.get_string(params, "udp", @default_udp_port_str)
          )

          if udp2 != nil && Ops.greater_than(udp2, 0) &&
              Ops.less_than(udp2, 65536)
            return SetUDP(udp2)
          else
            CommandLine.Print(_("Missing or invalid 'udp' option"))
          end
        end

        return false
      end

      if Builtins.haskey(params, "get")
        return GetUDP() if Builtins.haskey(params, "udp")

        return false
      end

      device = Ops.get_string(params, "device", "")
      address = Ops.get_string(params, "address", "")
      type = Ops.get_string(params, "type", "")
      ttl = Builtins.tointeger(Ops.get_string(params, "ttl", @default_ttl_str))
      udp = Builtins.tointeger(
        Ops.get_string(params, "udp", @default_udp_port_str)
      )

      return false if ttl == nil || udp == nil || device == nil || device == ""

      if Builtins.haskey(params, "add")
        return AddMedium(type, device, address, ttl, udp)
      elsif Builtins.haskey(params, "delete")
        return DeleteMedium(type, device, address, ttl, udp)
      else
        CommandLine.Print("ERROR: Missing or invalid command option!")
      end

      false
    end

    def ListAuth
      method = Ops.get_string(Heartbeat.authkeys, "method", "")
      password = Ops.get_string(Heartbeat.authkeys, "password", "")

      CommandLine.Print(
        Builtins.sformat(_("Authentication method: %1"), method)
      )

      if method == "sha1" || method == "md5"
        CommandLine.Print(
          Builtins.sformat(_("Authentication key: %1"), password)
        )
      end

      false
    end

    def SetAuth(method, key)
      if !Builtins.contains(["crc", "md5", "sha1"], method)
        # invalid method
        return false
      end

      curr_method = Ops.get_string(Heartbeat.authkeys, "method", "")
      curr_key = Ops.get_string(Heartbeat.authkeys, "password", "")

      if method != curr_method || key != curr_key
        Ops.set(Heartbeat.authkeys, "method", method)

        if method == "sha1" || method == "md5"
          Ops.set(Heartbeat.authkeys, "password", key)
        else
          Ops.set(Heartbeat.authkeys, "password", "")
        end

        Ops.set(Heartbeat.config, "modified", true)

        return true
      end

      false
    end

    def AuthHandler(params)
      params = deep_copy(params)
      return ListAuth() if Builtins.haskey(params, "list")

      if Builtins.haskey(params, "set")
        method = Ops.get_string(params, "method", "")
        key = Ops.get_string(params, "key", "")

        return SetAuth(method, key)
      end

      false
    end

    def StartStatus
      # %1 is "enabled" or "disabled"
      CommandLine.Print(
        Builtins.sformat(
          _("Start Heartbeat service at boot: %1"),
          # Automatic start at boot is either "enableb" or "disabled"
          Heartbeat.start_daemon ?
            _("enabled") :
            _("disabled")
        )
      )
      false
    end

    def EnableAutoStart(start)
      if start != Heartbeat.start_daemon
        Heartbeat.start_daemon_modified = true
        Heartbeat.start_daemon = start

        return true
      end

      false
    end

    def StartHandler(params)
      params = deep_copy(params)
      if Builtins.haskey(params, "status")
        return StartStatus()
      elsif Builtins.haskey(params, "enable")
        return EnableAutoStart(true)
      elsif Builtins.haskey(params, "disable")
        return EnableAutoStart(false)
      end

      false
    end

    def DoNotAbort
      false
    end

    def ReadHandler
      # register abort callback
      Heartbeat.AbortFunction = fun_ref(method(:DoNotAbort), "boolean ()")
      Heartbeat.Read
    end
  end
end
