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
  module HeartbeatHelpsInclude
    def initialize_heartbeat_helps(include_target)
      textdomain "heartbeat"

      # All helps are here
      @HELPS = {
        "read"           => _(
          "<p><b><big>Initializing Heartbeat Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          _(
            "<p><b><big>Aborting Initialization:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        "write"          => _(
          "<p><b><big>Saving Heartbeat Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs whether it is safe to do so.\n" +
              "</p>\n"
          ),
        "node_conf"      => _(
          "<p><b>Node Configuration</b> lets you specify and\n" +
            "add nodes to your cluster. This installation program lets you create\n" +
            "a new cluster or add nodes to an existing cluster. To add new nodes\n" +
            "to an existing cluster, you must run this installation program from a\n" +
            "node that is already in the cluster, not on a node that you want to add\n" +
            "to the cluster.</p>\n"
        ) +
          _(
            "<p>This cluster installation program does not copy the Heartbeat\n" +
              "software package to cluster nodes. Prior to running this installation program, the\n" +
              "Heartbeat software package must be installed on all nodes that will be\n" +
              "part of your cluster.</p>"
          ) +
          _(
            "<p>To add a node to the cluster, enter the name of the node\n" +
              "then click <b>Add</b>. Repeat this process for each\n" +
              "node to add to the cluster. Find node names for servers\n" +
              "by entering the <tt>uname -n</tt> command on each node.</p>\n"
          ) +
          _(
            "<p>If you need to specify a different node name after adding a node to the cluster,\ndouble-click the node to edit, change its name, then click <b>Edit</b>.</p>\n"
          ),
        "media_conf"     => _(
          "<p><b>Heartbeat Media Configuration</b> lets you\n" +
            " specify the method Heartbeat should use for internal communication\n" +
            "between cluster nodes. This provides a way for cluster nodes to signal\n" +
            "that they are alive to other nodes in the cluster. For proper redundancy,\n" +
            "you should specify more than one heartbeat medium if possible.</p>\n"
        ) +
          _(
            "<p>Choose at least one <b>Heartbeat Medium</b> and, if possible,\n" +
              " two or more. After specifying a heartbeat medium, click <b>Add</b> to add\n" +
              "that medium type to Heartbeat.</p>\n"
          ) +
          _(
            "<p>If you choose <b>Broadcast</b>, select one of the available network\ndevices in the device list.</p>\n"
          ) +
          _(
            "<p>For <b>Multicast</b>, choose a network device, multicast\n" +
              "group to join (class D multicast address 224.0.0.0-239.255.255.255), and\n" +
              "the ttl value (1-255).</p>\n"
          ) +
          _(
            "<p><b>UDP Port</b> sets the UDP port that is used for the\n" +
              "broadcast media. Leave this set to the default value (694)\n" +
              "unless you are running multiple Heartbeat clusters on the same network\n" +
              "segment, in which case you need to run each cluster on a different port\n" +
              "number.</p>\n"
          ),
        "auth_conf"      => _(
          "<p>Specify the authentication method to\n" +
            " use for network communication between cluster nodes. Choosing\n" +
            "an authentication method protects against network attacks.</p>\n"
        ) +
          _(
            "<p>Both the <b>md5</b> and <b>sha1</b> methods require a\n" +
              " <i>shared secret</i>, which is used to protect and authenticate\n" +
              " messages. The <b>crc</b> method does not perform message authentication\n" +
              " and only protects against corruption, not against attacks.</p>\n"
          ) +
          _(
            "<p>The <b>sha1</b> method is recommended because it provides the\n" +
              "    strongest authentication scheme available. The authentication key\n" +
              "(password) specified is used on all nodes in the cluster.</p>\n"
          ),
        "resources_conf" => _(
          "<p><b>Resources</b> -- specify which resources are handled by Heartbeat\n" +
            "and how Heartbeat should handle failback (migration of resources back to\n" +
            "a node after a failure has been resolved).</p>\n"
        ) +
          _(
            "<p>If you set <b>Automatic Failback</b> to <i>on</i>, Heartbeat \n" +
              "migrates resources back to the primary owner as soon as it becomes\n" +
              "available again. This automatically restores the balancing of\n" +
              "resources between the nodes, but requires that the resources are briefly\n" +
              "stopped so they can be cleanly started, leading to a minor\n" +
              "interruption of service.</p>\n"
          ) +
          _(
            "<p>For most scenarios, <i>off</i> is the correct choice. It requires \n" +
              "the administrator to trigger the failback of resources manually\n" +
              "(using the hb_standby command line tool) as soon as the failure is\n" +
              "resolved. This allows him to schedule a maintenance window and not\n" +
              "interrupt the service even more.</p>\n"
          ) +
          _(
            "<p><i>legacy</i> is the old default for compatibility with former\n" +
              "Heartbeat releases. It activates the automatic failback if not all\n" +
              "nodes support the new directive yet. Explicitly choosing either \n" +
              "<i>on</i> or <i>off</i> is recommended for new deployments.</p>\n"
          ) +
          _(
            "<p>Adding a resource to a given node places the resource under\n" +
              "Heartbeat's control. It will be started and stopped automatically by\n" +
              "Heartbeat. Make sure the resource is not started by anything\n" +
              "else.</p>\n"
          ) +
          _(
            "<p>Heartbeat primarily starts the resource on the node to which it is\n" +
              "assigned if both nodes are healthy and up. See the <b>auto_failback</b>\n" +
              "setting above.</p>\n"
          ) +
          _(
            "<p>Specify any init script name as a resource or a specify a special \n" +
              "Heartbeat resource script (provided in the <i>/etc/ha.d/resource.d</i>\n" +
              "directory). Some of the latter take additional arguments, which are\n" +
              "separated from the resource script name itself by <i>::</i>, for\n" +
              "example, <i>Filesystem::/dev/sda1::/mnt::reiserfs</i>. Check the\n" +
              "documentation for the resource scripts.</p>\n"
          ),
        "stonith_conf"   => _(
          "<p>To protect the shared data, <b>STONITH</b>\n" +
            " must be configured. Heartbeat is capable of driving a number of\n" +
            "serial and network power switches to prevent a potentially faulty\n" +
            "node from corrupting shared data.</p>\n"
        ) +
          _(
            "<p>STONITH needs to know which nodes can access the power\n" +
              " switch. Enter or select the name of the node in <b>Host From</b>.\n" +
              " For a serial power switch, this is a specific node name.\n" +
              " For a network power switch, you should typically enter an asterisk\n" +
              " (*) to indicate that it is accessible from all nodes.</p>\n"
          ) +
          _(
            "<p>The <b>STONITH Type</b> is the name of the module that\n" +
              " is used to control the power switch. <b>Parameters</b> are\n" +
              " specific to the module specified. See the <tt>stonith -h</tt>\n" +
              " command line tool for a list of supported modules and\n" +
              " the parameters they accept.</p>\n"
          ),
        "startup_conf"   => _(
          "<p><b><big>Booting</big></b><br>\n" +
            "To start the Heartbeat software each time this cluster server\n" +
            "is booted, select <b>On</b>. If you select <b>Off</b>, you \n" +
            "must start Heartbeat manually each time this cluster server\n" +
            "is booted. You can start the Heartbeat server manually using\n" +
            "the <tt>/etc/init.d/heartbeat start</tt> command.</p>\n" +
            "<p>To propagate the configuration to all nodes of the cluster and \n" +
            "to enable heartbeat service on them, run the command line utility \n" +
            "<tt>/usr/lib/heartbeat/ha_propagate</tt> on this node after the \n" +
            "configuration is saved.</p>\n"
        ),
        "timeouts_conf"  => _(
          "<p>Heartbeat uses a variety of timers to tune and configure its behavior.\nAll timers are specified in seconds.</p>\n"
        ) +
          _(
            "<p><b>Keep Alive</b> specifies the interval at which a node announces itself on\nthe network.</p>\n"
          ) +
          _(
            "<p><b>Dead Time</b> is the time after which a node is presumed to be dead.\nIt should probably default to five times the Keep Alive interval.</p>\n"
          ) +
          _(
            "<p><b>Warn Time</b> is the time after which Heartbeat warns in the log files\n" +
              "that a node has been slow in sending its heartbeats. This should\n" +
              "probably default to three times the Keep Alive interval.</p>\n"
          ) +
          _(
            "<p><b>Init Dead Time</b> is the time a node waits after start-up for the other\n" +
              "nodes, given that sometimes network interfaces, routing, etc., take a\n" +
              "while to stabilize. It should default to at least twice the Dead Time.</p>\n"
          ) +
          _(
            "If the <b>Watchdog Timer</b> is enabled, Heartbeat uses\n" +
              "the in-kernel watchdog for monitoring the local node itself. If\n" +
              "Heartbeat does not write to that file every sixty seconds, the kernel \n" +
              "forcibly reboots the node.</p>\n"
          ),
        "ipfail_conf"    => _(
          "<p><b>IP Fail</b> allows monitoring of external\n" +
            "hosts and moving the resources accordingly (i.e., to the host with the\n" +
            "<i>best</i> connectivity).</p>\n"
        ) +
          _(
            "<p>If enabled, Heartbeat needs a <b>Ping List</b> of external nodes to ping.\nThe minimum if IP fail is enabled is one. A maximum of four to eight nodes seems sensible.</p>\n"
          ) +
          _(
            "<p>For more complex configurations, Heartbeat also supports <i>Ping Groups</i>."
          ),
        "group_conf"     => _(
          "A list of IP addresses is grouped together and if any\n" +
            "of them is reachable, the node is deemed able to communicate with\n" +
            "the <i>Ping Group</i>.</p>\n"
        )
      } 

      # EOF
    end
  end
end
