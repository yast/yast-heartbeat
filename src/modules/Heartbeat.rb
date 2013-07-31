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
# File:	modules/Heartbeat.ycp
# Package:	Configuration of heartbeat
# Summary:	Heartbeat settings, input and output functions
# Authors:	Martin Lazar <mlazar@suse.cz>
#
# $Id$
#
# Representation of the configuration of heartbeat.
# Input and output routines.
require "yast"

module Yast
  class HeartbeatClass < Module
    def main
      textdomain "heartbeat"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Service"

      Yast.import "Mode"
      Yast.import "PackageSystem"

      @config = {}
      @authkeys = {}
      @resources = {}
      @ha_dir = "/etc/ha.d"
      @start_daemon = false
      @start_daemon_modified = false
      @resources_modified = false
      @firstrun = false


      @proposal_valid = false

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      @resources_modified || Ops.get_boolean(@config, "modified", false) ||
        Ops.get_boolean(@authkeys, "modified", false) || @start_daemon_modified
    end

    # Settings: Define all variables needed for configuration of heartbeat
    # TODO FIXME: Define all the variables necessary to hold
    # TODO FIXME: the configuration here (with the appropriate
    # TODO FIXME: description)
    # TODO FIXME: For example:
    #   /**
    #    * List of the configured cards.
    #    */
    #   list cards = [];
    #
    #   /**
    #    * Some additional parameter needed for the configuration.
    #    */
    #   boolean additional_parameter = true;

    # Read all heartbeat settings
    # @return true on success
    def Read
      # Heartbeat read dialog caption
      caption = _("Initializing Heartbeat Configuration")

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        4,
        [
          _("Read previous settings"),
          _("Read resources"),
          _("Read authentication keys"),
          _("Read daemon status")
        ],
        [
          _("Reading previous settings..."),
          _("Reading resources..."),
          _("Reading authentication keys..."),
          _("Reading daemon status..."),
          _("Finished")
        ],
        ""
      )

      Progress.NextStage

      # check installed packages
      if !Mode.test &&
          !PackageSystem.CheckAndInstallPackagesInteractive(["heartbeat"])
        return false
      end

      if Ops.greater_than(
          SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/ha.cf")),
          0
        )
        Builtins.foreach(
          [
            "debugfile",
            "logfile",
            "logfacility",
            "keepalive",
            "deadtime",
            "warntime",
            "initdead",
            "udpport",
            "baud",
            "auto_failback",
            "hopfudge",
            "deadping",
            "watchdog",
            "hbgenmethod",
            "realtime",
            "debug",
            "autojoin",
            "crm"
          ]
        ) do |key|
          vals = Convert.to_list(
            SCR.Read(
              Builtins.topath(Builtins.sformat(".etc.ha_d.ha_cf.\"%1\"", key))
            )
          )
          if Ops.greater_than(Builtins.size(vals), 0)
            Ops.set(
              @config,
              key,
              Ops.get_string(vals, Ops.subtract(Builtins.size(vals), 1), "")
            )
            Builtins.y2milestone(
              "%1  = '%2'",
              key,
              Ops.get_string(@config, key, "")
            )
          end
        end

        Builtins.foreach(
          [
            "serial",
            "bcast",
            "node",
            "ping",
            "stonith",
            "stonith_host",
            "ping_group",
            "respawn",
            "apiauth",
            "ucast",
            "mcast"
          ]
        ) do |key|
          vals = Convert.convert(
            SCR.Read(
              Builtins.topath(Builtins.sformat(".etc.ha_d.ha_cf.\"%1\"", key))
            ),
            :from => "any",
            :to   => "list <string>"
          )
          if Ops.greater_than(Builtins.size(vals), 0)
            u = []
            Builtins.foreach(vals) do |s|
              #		    list<string> l = splitstring(s, " \t");
              #		    l = filter(string s, l, { return s != ""; });
              u = Builtins.add(u, s) #		    y2milestone("%1  = (%2)", key, mergestring(l, ", "));
            end
            Ops.set(@config, key, u)
          end
        end
      else
        @firstrun = true

        aa = []
        #	aa = add(aa, "mgmtd uid=hacluster,root");
        aa = Builtins.add(aa, "evms uid=hacluster,root")
        Ops.set(@config, "apiauth", aa)

        rs = []
        # 	map unamemap = (map)SCR::Execute(.target.bash_output, "uname -m");
        # 	string machine = deletechars(unamemap["stdout"]:"", "\n");
        # 	if (machine == "x86_64") {
        # 	    rs = add(rs, "root /usr/lib64/heartbeat/mgmtd -v");
        # 	} else {
        #  	    rs = add(rs, "root /usr/lib/heartbeat/mgmtd -v");
        # 	}
        rs = Builtins.add(rs, "root /sbin/evmsd")
        Ops.set(@config, "respawn", rs)

        bc = []
        bc = Builtins.add(bc, "eth0")
        Ops.set(@config, "bcast", bc)

        Ops.set(@config, "autojoin", "any")
        Ops.set(@config, "crm", "true")
      end
      Ops.set(@config, "modified", false)

      return false if Abort()
      Progress.NextStage
      if Ops.greater_than(
          SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/haresources")),
          0
        )
        nodes = SCR.Dir(path(".etc.ha_d.haresources"))
        Builtins.foreach(nodes) do |node|
          r = Convert.to_string(
            SCR.Read(
              Builtins.topath(
                Builtins.sformat(".etc.ha_d.haresources.\"%1\"", node)
              )
            )
          )
          Builtins.y2milestone("readed resource %1(%2)", node, r)
          @resources = Builtins.add(
            @resources,
            node,
            Builtins.splitstring(r, " \t")
          )
        end
      end
      @resources_modified = false


      return false if Abort()
      Progress.NextStage
      if Ops.greater_than(
          SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/authkeys")),
          0
        )
        id = Convert.to_string(SCR.Read(path(".etc.ha_d.authkeys.auth")))
        if id != nil && Builtins.regexpmatch(id, "^[0-9]+$")
          opt = Convert.to_string(
            SCR.Read(
              Builtins.topath(Builtins.sformat(".etc.ha_d.authkeys.\"%1\"", id))
            )
          )
          tok = Builtins.regexptokenize(opt, "^[ \t]*([^ \t]+)[ \t]*(.*)$")
          @authkeys = {
            "id"       => id,
            "method"   => Ops.get_string(tok, 0, ""),
            "password" => Ops.get_string(tok, 1, "")
          }
        end
      end
      Ops.set(@authkeys, "modified", false)

      return false if Abort()
      Progress.NextStage
      @start_daemon = Service.Enabled("heartbeat")
      @start_daemon_modified = false

      return false if Abort()
      # Progress finished
      Progress.NextStage

      return false if Abort()
      true
    end

    # Write all heartbeat settings
    # @return true on success
    def Write
      # Heartbeat read dialog caption
      caption = _("Saving Heartbeat Configuration")

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        4,
        [
          _("Write settings"),
          _("Write resources"),
          _("Write authentication keys"),
          _("Restart services")
        ],
        [
          _("Writing settings..."),
          _("Writing resources..."),
          _("Writing authentication keys..."),
          _("Restarting services..."),
          _("Finished")
        ],
        ""
      )

      return false if Abort()
      Progress.NextStage

      # Write ha.cf
      if Ops.get_boolean(@config, "modified", false)
        if Ops.less_than(
            SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/ha.cf")),
            0
          )
          SCR.Write(path(".target.string"), Ops.add(@ha_dir, "/ha.cf"), "")
        end

        Builtins.foreach(
          [
            "debugfile",
            "logfile",
            "logfacility",
            "keepalive",
            "deadtime",
            "warntime",
            "initdead",
            "udpport",
            "baud",
            "auto_failback",
            "watchdog",
            "hopfudge",
            "deadping",
            "hbgenmethod",
            "realtime",
            "debug",
            "autojoin",
            "crm"
          ]
        ) do |key|
          #	    if (config[key]:nil != nil) {
          Builtins.y2milestone(
            "write %1  = '%2'",
            key,
            Ops.get_string(@config, key, "")
          )
          SCR.Write(
            Builtins.topath(Builtins.sformat(".etc.ha_d.ha_cf.\"%1\"", key)),
            Ops.get(@config, key) != nil ? [Ops.get(@config, key)] : nil
          ) #	    }
        end


        Builtins.foreach(
          [
            "serial",
            "bcast",
            "mcast",
            "ucast",
            "stonith",
            "stonith_host",
            "node",
            "ping",
            "ping_group",
            "respawn",
            "apiauth"
          ]
        ) do |key|
          #          SCR::Write(topath(sformat(".etc.ha_d.ha_cf.\"%1\"", key)), nil);
          #	    if (size(config[key]:[]) > 0) {
          l = Ops.get_list(@config, key, [])
          Builtins.y2milestone(
            "write %1  = [%2]",
            key,
            Builtins.mergestring(l, ", ")
          )
          SCR.Write(
            Builtins.topath(Builtins.sformat(".etc.ha_d.ha_cf.\"%1\"", key)),
            Ops.greater_than(Builtins.size(l), 0) ? l : nil
          ) #	    }
        end
        SCR.Write(path(".etc.ha_d.ha_cf"), nil)
      end


      return false if Abort()
      Progress.NextStage

      # Write haresources
      if @resources_modified
        if Ops.less_than(
            SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/haresources")),
            0
          )
          SCR.Write(
            path(".target.string"),
            Ops.add(@ha_dir, "/haresources"),
            ""
          )
        end


        Builtins.foreach(SCR.Dir(path(".etc.ha_d.haresources"))) do |key|
          SCR.Write(
            Builtins.topath(
              Builtins.sformat(".etc.ha_d.haresources.\"%1\"", key)
            ),
            nil
          )
        end

        Builtins.foreach(
          Convert.convert(
            @resources,
            :from => "map",
            :to   => "map <string, list>"
          )
        ) do |node, r|
          opt = Builtins.mergestring(
            Convert.convert(r, :from => "list", :to => "list <string>"),
            " "
          )
          opt = nil if opt == ""
          SCR.Write(
            Builtins.topath(
              Builtins.sformat(".etc.ha_d.haresources.\"%1\"", node)
            ),
            opt
          )
          Builtins.y2milestone("writed resource %1(%2)", node, opt)
        end
        SCR.Write(path(".etc.ha_d.haresources"), nil)
      end

      return false if Abort()
      Progress.NextStage

      # Write authkeys
      if Ops.get_boolean(@authkeys, "modified", false)
        if Ops.less_than(
            SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/authkeys")),
            0
          )
          SCR.Write(path(".target.string"), Ops.add(@ha_dir, "/authkeys"), "")
        end

        id = Ops.get_string(@authkeys, "id", "1")
        opt = Ops.add(
          Ops.add(Ops.get_string(@authkeys, "method", "crc"), " "),
          Ops.get_string(@authkeys, "password", "")
        )
        SCR.Write(path(".etc.ha_d.authkeys.auth"), id)
        SCR.Write(
          Builtins.topath(Builtins.sformat(".etc.ha_d.authkeys.\"%1\"", id)),
          opt
        )
        SCR.Write(path(".etc.ha_d.authkeys"), nil)
        Builtins.y2milestone("writed authkeys %1 %2", id, opt)
      elsif Ops.less_than(
          SCR.Read(path(".target.size"), Ops.add(@ha_dir, "/authkeys")),
          0
        )
        SCR.Write(path(".target.string"), Ops.add(@ha_dir, "/authkeys"), "")
        SCR.Write(path(".etc.ha_d.authkeys.auth"), "1")
        SCR.Write(path(".etc.ha_d.authkeys.\"1\""), "crc")
      end
      SCR.Execute(
        path(".target.bash"),
        Ops.add(Ops.add("/bin/chown 0.0 ", @ha_dir), "/authkeys")
      )
      SCR.Execute(
        path(".target.bash"),
        Ops.add(Ops.add("/bin/chmod 0600 ", @ha_dir), "/authkeys")
      )

      return false if Abort()
      Progress.NextStage

      # Restart services
      if !@start_daemon
        Service.Stop("heartbeat")
        Report.Error(Service.Error) if !Service.Disable("heartbeat")
      else
        Report.Error(Service.Error) if !Service.Enable("heartbeat")
        Service.Restart("heartbeat")
      end


      return false if Abort()
      # Progress finished
      Progress.NextStage

      return false if Abort()
      true
    end

    # Get all heartbeat settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      # TODO FIXME: your code here (fill the above mentioned variables)...
      true
    end

    # Dump the heartbeat settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      # TODO FIXME: your code here (return the above mentioned variables)...
      {}
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      # TODO FIXME: your code here...
      # Configuration summary text for autoyast
      [_("Configuration Summary..."), []]
    end

    # Create an overview table with all configured cards
    # @return table items
    def Overview
      # TODO FIXME: your code here...
      []
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      # TODO FIXME: your code here...
      { "install" => ["heartbeat"], "remove" => [""] }
    end

    publish :variable => :config, :type => "map"
    publish :variable => :authkeys, :type => "map"
    publish :variable => :resources, :type => "map"
    publish :variable => :ha_dir, :type => "string"
    publish :variable => :start_daemon, :type => "boolean"
    publish :variable => :start_daemon_modified, :type => "boolean"
    publish :variable => :resources_modified, :type => "boolean"
    publish :variable => :firstrun, :type => "boolean"
    publish :function => :Modified, :type => "boolean ()"
    publish :variable => :proposal_valid, :type => "boolean"
    publish :variable => :write_only, :type => "boolean"
    publish :variable => :AbortFunction, :type => "boolean ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :Overview, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  Heartbeat = HeartbeatClass.new
  Heartbeat.main
end
