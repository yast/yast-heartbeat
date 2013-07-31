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
  module HeartbeatWizardsInclude
    def initialize_heartbeat_wizards(include_target)
      textdomain "heartbeat"

      Yast.import "Sequencer"
      Yast.import "Wizard"

      Yast.include include_target, "heartbeat/dialogs.rb"
      Yast.include include_target, "heartbeat/common.rb"

      @Aliases = {
        "startup_conf"   => lambda { ConfigureStartUpDialog() },
        "node_conf"      => lambda { ConfigureNodeDialog() },
        "media_conf"     => lambda { ConfigureMediaDialog() },
        "auth_conf"      => lambda { ConfigureAuthDialog() },
        "resources_conf" => lambda { ConfigureResourcesDialog() },
        "stonith_conf"   => lambda { ConfigureStonithDialog() },
        "timeouts_conf"  => lambda { ConfigureTimeoutsDialog() },
        "ipfail_conf"    => lambda { ConfigureIpfailDialog() },
        "group_conf"     => lambda { ConfigurePingGroupDialog() }
      }
    end

    def TabSequence
      sequence = { "ws_start" => Ops.get(@DIALOG, 0, "") }
      anywhere = { :abort => :abort, :next => :next }

      Builtins.foreach(@DIALOG) do |key|
        anywhere = Builtins.add(
          anywhere,
          Builtins.symbolof(Builtins.toterm(key)),
          key
        )
      end
      Builtins.foreach(@DIALOG) do |key|
        sequence = Builtins.add(sequence, key, anywhere)
      end

      # UI initialization
      Wizard.OpenTreeNextBackDialog

      tree = []
      Builtins.foreach(@DIALOG) do |key|
        tree = Wizard.AddTreeItem(
          tree,
          Ops.get_string(@PARENT, key, ""),
          Ops.get_string(@NAME, key, ""),
          key
        )
      end 


      Wizard.CreateTree(tree, "")
      Wizard.SetDesktopTitleAndIcon("heartbeat")

      # Buttons redefinition


      Wizard.SetNextButton(:next, Label.FinishButton)

      if UI.WidgetExists(Id(:wizardTree))
        #we should probably not use `help ID here
        #`help button is defined within Wizard standard bottom button box
        #Wizard::SetBackButton((`help, Label::HelpButton()));
        Wizard.SetAbortButton(:abort, Label.CancelButton)
      else
        UI.WizardCommand(term(:SetNextButtonLabel, Label.FinishButton))
        UI.WizardCommand(term(:SetAbortButtonLabel, Label.CancelButton))
      end
      #rather, always hide back button
      Wizard.HideBackButton

      Wizard.SelectTreeItem(Ops.get_string(sequence, "ws_start", ""))

      ret = Sequencer.Run(@Aliases, sequence)

      Wizard.CloseDialog

      deep_copy(ret)
    end

    def FirstRunSequence
      sequence = {
        "ws_start"     => "node_conf",
        "node_conf"    => {
          :next  => "auth_conf",
          :back  => "node_conf",
          :abort => :abort
        },
        "auth_conf"    => {
          :next  => "media_conf",
          :back  => "node_conf",
          :abort => :abort
        },
        "media_conf"   => {
          :next  => "startup_conf",
          :back  => "media_conf",
          :abort => :abort
        },
        "startup_conf" => {
          :next  => :next,
          :back  => "media_conf",
          :abort => :abort
        }
      }

      ret = Sequencer.Run(@Aliases, sequence)

      deep_copy(ret)
    end

    def MainSequence
      if Heartbeat.firstrun
        return FirstRunSequence()
      else
        return TabSequence()
      end
    end

    # Whole configuration of heartbeat
    # @return sequence result
    def HeartbeatSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.CreateDialog
      Wizard.SetDesktopTitleAndIcon("heartbeat")

      ret = Sequencer.Run(aliases, sequence)

      Wizard.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of heartbeat but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def HeartbeatAutoSequence
      # Initialization dialog caption
      caption = _("Heartbeat Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = TabSequence()

      Wizard.CloseDialog
      deep_copy(ret)
    end
  end
end
