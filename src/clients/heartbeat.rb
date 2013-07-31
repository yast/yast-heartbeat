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
  class HeartbeatClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of heartbeat</h3>

      textdomain "heartbeat"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Heartbeat module started")

      Yast.import "CommandLine"
      Yast.import "Report"

      Yast.include self, "heartbeat/wizards.rb"
      Yast.include self, "heartbeat/commandline.rb"

      @cmdline_description = {
        "id"         => "heartbeat",
        # Command line help text for the Heartbeat module
        "help"       => _(
          "Configuration of high availability (HA) cluster using Heartbeat service."
        ),
        "guihandler" => fun_ref(method(:HeartbeatSequence), "any ()"),
        "initialize" => fun_ref(method(:ReadHandler), "boolean ()"),
        "finish"     => fun_ref(Heartbeat.method(:Write), "boolean ()"),
        "actions"    => {
          # functionality description
          "node"           => {
            "handler" => fun_ref(method(:NodeHandler), "boolean (map)"),
            # translators: command line help text for add action
            "help"    => _(
              "Configure a list of servers for the cluster."
            )
          },
          "medium"         => {
            "handler" => fun_ref(method(:MediumHandler), "boolean (map)"),
            # translators: command line help text for add action
            "help"    => _(
              "Set the communication between the nodes of the cluster."
            )
          },
          "authentication" => {
            "handler" => fun_ref(method(:AuthHandler), "boolean (map)"),
            # translators: command line help text for add action
            "help"    => _(
              "Configure authentication of the nodes."
            )
          },
          "start"          => {
            "handler" => fun_ref(method(:StartHandler), "boolean (map)"),
            # translators: command line help text for add action
            "help"    => _(
              "Configure automatic start of the service at boot."
            )
          }
        },
        # descriptions of options
        "options"    => {
          "add"     => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Add a new item to the list."
            )
          },
          "delete"  => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Delete an item from the list."
            )
          },
          "list"    => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Display the configuration."
            )
          },
          "name"    => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Name of the node in the cluster."
            ),
            "type" => "string"
          },
          "type"    => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Set the communication mode to 'bcast' for broadcast or 'mcast' for multicast."
            ),
            "type" => "string"
          },
          "device"  => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Network device (e.g. eth0) used for communication."
            ),
            "type" => "string"
          },
          "address" => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "IP address of the multicast group (224.0.0.0 - 239.255.255.255)."
            ),
            "type" => "string"
          },
          "ttl"     => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "TTL value (1-255, default is 2)."
            ),
            "type" => "integer"
          },
          "udp"     => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "UDP port number (default is 694)."
            ),
            "type" => "integer"
          },
          "method"  => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Set authentication method to 'crc' (no security), 'sha1' or 'md5'."
            ),
            "type" => "string"
          },
          "key"     => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "The authentication key."
            ),
            "type" => "string"
          },
          "enable"  => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Enable automatic start of the service at boot."
            )
          },
          "disable" => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Disable automatic start of the service at boot."
            )
          },
          "set"     => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Set the configuration."
            )
          },
          "status"  => {
            # translators: command line help text for the 'play' option
            "help" => _(
              "Print status of the automatic start at boot."
            )
          }
        },
        # map options to commands
        "mappings"   => {
          "node"           => ["add", "delete", "list", "name"],
          "medium"         => [
            "add",
            "delete",
            "list",
            "type",
            "device",
            "address",
            "ttl",
            "set",
            "udp"
          ],
          "authentication" => ["set", "list", "method", "key"],
          "start"          => ["status", "enable", "disable"]
        }
      }

      # is this proposal or not?
      @propose = false
      @args = WFM.Args
      if Ops.greater_than(Builtins.size(@args), 0)
        if Ops.is_path?(WFM.Args(0)) && WFM.Args(0) == path(".propose")
          Builtins.y2milestone("Using PROPOSE mode")
          @propose = true
        end
      end

      # main ui function
      @ret = nil

      if @propose
        @ret = HeartbeatAutoSequence()
      else
        @ret = CommandLine.Run(@cmdline_description)
      end
      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("Heartbeat module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::HeartbeatClient.new.main
