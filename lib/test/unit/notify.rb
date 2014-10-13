# Copyright (C) 2010-2014  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "pathname"
require "erb"
require "test/unit/autorunner"
require "test/unit/notify/version"

module Test
  module Unit
    AutoRunner.prepare do |auto_runner|
      Notify.setup_auto_runner(auto_runner)
    end

    AutoRunner.setup_option do |auto_runner, options|
      options.on("--[no-]notify",
                 "Notify test result at the last.",
                 "(default is auto [#{Notify.enabled?}])") do |use_notify|
        Notify.setup_auto_runner(auto_runner, use_notify)
      end
    end

    module Notify
      class << self
        @@enable = nil

        # Enables test result notification by default. It
        # can be disabled by `--no-notify` command line
        # option.
        def enable
          @@enable = true
        end

        # Disables test result notification by default. It
        # can be disabled by `--notify` command line option.
        def disable
          @@enable = false
        end

        # @deprecated Use {Notify.enable} or {Notify.disable} instead.
        def enable=(enable)
          self.default = enable
        end

        # @return [Boolean] return whether test result notification
        #   is enabled or not.
        def enabled?
          @@enable = Notifier.available? if @@enable.nil?
          @@enable
        end

        # @private
        def setup_auto_runner(auto_runner, enable=nil)
          auto_runner.listeners.reject! do |listener|
            listener.is_a?(Notify::Notifier)
          end
          enable = enabled? if enable.nil?
          auto_runner.listeners << Notifier.new if enable
        end
      end

      # @private
      class NotifyCommand
        def available?
          paths.any? do |path|
            File.exist?(File.join(path, @command))
          end
        end

        private
        def paths
          path_env = ENV["PATH"]
          if path_env.nil?
            default_paths
          else
            path_env.split(File::PATH_SEPARATOR)
          end
        end

        def default_paths
          ["/usr/local/bin", "/usr/bin", "/bin"]
        end
      end

      # @private
      class NotifySend < NotifyCommand
        include ERB::Util

        def initialize
          @command = "notify-send"
        end

        def run(parameters)
          expire_time = parameters[:expire_time] * 1000
          urgency = parameters[:urgency]
          title = parameters[:title]
          message = h(parameters[:message])
          icon = parameters[:icon]

          command_line = [
            @command,
            "--app-name", title,
            "--expire-time", expire_time.to_s,
            "--urgency", urgency,
          ]
          command_line.concat(["--icon", icon.to_s]) if icon
          command_line << title
          command_line << message
          system(*command_line)
        end
      end

      # @private
      class Growlnotify < NotifyCommand
        def initialize
          @command = "growlnotify"
        end

        def run(parameters)
          priority = urgency_to_piroity(parameters[:urgency])
          title = parameters[:title]
          message = parameters[:message]
          image = parameters[:icon]

          command_line = [
            @command,
            "--priority", priority,
            "--message", message,
          ]
          command_line.concat(["--image", image.to_s]) if image
          command_line << title
          system(*command_line)
        end

        private
        def urgency_to_piroity(urgency)
          case urgency
          when "normal"
            "Normal"
          when "critical"
            "Emergency"
          else
            "Normal"
          end
        end
      end

      # @private
      class GrowlnotifyForWindows < NotifyCommand
        def initialize
          @command = "growlnotify.exe"
        end

        URGENCIES = {
          "critical" => 2,
        }

        URGENCIES.default = 0

        def run(parameters)
          priority = URGENCIES[parameters[:urgency]]
          title    = parameters[:title]
          message  = parameters[:message]
          image    = parameters[:icon]
          command_line = [@command, "/t:#{title}", "/p:#{priority}"]
          command_line << "/i:#{image.to_s}" if image
          command_line << message
          system(*command_line)
        end
      end

      # @private
      class TerminalNotifier < NotifyCommand
        include ERB::Util

        def initialize
          @command = "terminal-notifier"
        end

        def run(parameters)
          title = parameters[:title]
          message = parameters[:message]
          icon = parameters[:icon]

          command_line = [
            @command,
            "-title", title,
            "-message", message,
          ]
          command_line.concat(["-appIcon", icon.to_s]) if icon
          system(*command_line)
        end
      end

      class Notifier
        class << self
          # @return [Boolean] return `true` if test result notification
          #   is available.
          def available?
            not command.nil?
          end

          # @private
          def command
            @@command ||= commands.find {|command| command.available?}
          end

          # @private
          def commands
            [
              NotifySend.new,
              Growlnotify.new,
              GrowlnotifyForWindows.new,
              TerminalNotifier.new,
            ]
          end
        end

        base_dir = Pathname(__FILE__).dirname.parent.parent.parent.expand_path
        # @private
        ICON_DIR = base_dir + "data" + "icons"

        # @private
        def initialize
          @theme = "kinotan"
        end

        # @private
        def attach_to_mediator(mediator)
          mediator.add_listener(UI::TestRunnerMediator::STARTED,
                                &method(:started))
          mediator.add_listener(UI::TestRunnerMediator::FINISHED,
                                &method(:finished))
        end

        # @private
        def started(result)
          @result = result
        end

        # @private
        def finished(elapsed_time)
          command = self.class.command
          return if command.nil?

          title = "%s [%g%%] (%gs)" % [
            @result.status,
            @result.pass_percentage,
            elapsed_time,
          ]
          parameters = {
            :expire_time => 5,
            :icon => guess_suitable_icon,
            :urgency => urgency,
            :title => title,
            :message => @result.summary,
          }
          command.run(parameters)
        end

        private
        def guess_suitable_icon
          icon_dir = ICON_DIR + @theme
          status = @result.status
          icon_base_names = [status]
          if @result.passed?
            icon_base_names << "pass"
          else
            case status
            when "failure"
              icon_base_names << "error"
            when "error"
              icon_base_names << "failure"
            end
          end
          icon_base_names << "default"
          icon_base_names.each do |base_name|
            icon = icon_dir + "#{base_name}.png"
            return icon if icon.exist?
          end
          nil
        end

        def urgency
          if @result.passed?
            "normal"
          else
            "critical"
          end
        end
      end
    end
  end
end
