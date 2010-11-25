#--
#
# Author:: Kouhei Sutou
# Copyright::
#   * Copyright (c) 2010 Kouhei Sutou <kou@clear-code.com>
# License:: Ruby license.

require 'pathname'
require 'erb'
require 'test/unit'

module Test
  module Unit
    AutoRunner.prepare do |auto_runner|
      Notify.enable(auto_runner) if Notify.enable?
    end

    AutoRunner.setup_option do |auto_runner, options|
      options.on("--[no-]notify",
                 "Notify test result at the last.") do |use_notify|
        Notify.disable(auto_runner)
        Notify.enable(auto_runner) if use_notify
      end
    end

    module Notify
      VERSION = "0.1.1"

      class << self
        def enable(auto_runner)
          auto_runner.listeners << Notifier.new
        end

        def disable(auto_runner)
          auto_runner.listeners.reject! do |listener|
            listener.is_a?(Notify::Notifier)
          end
        end

        @@enable = false
        def enable=(enable)
          @@enable = enable
        end

        def enable?
          @@enable
        end
      end

      class Notifier
        include ERB::Util

        base_dir = Pathname(__FILE__).dirname.parent.parent.parent.expand_path
        ICON_DIR = base_dir + "data" + "icons"
        def initialize
          @theme = "kinotan"
        end

        def attach_to_mediator(mediator)
          mediator.add_listener(UI::TestRunnerMediator::STARTED,
                                &method(:started))
          mediator.add_listener(UI::TestRunnerMediator::FINISHED,
                                &method(:finished))
        end

        def started(result)
          @result = result
        end

        def finished(elapsed_time)
          case RUBY_PLATFORM
          when /mswin|mingw|cygwin/
            # how?
          when /darwin/
            # growl?
          else
            notify_by_notify_send(elapsed_time)
          end
        end

        def notify_by_notify_send(elapsed_time)
          icon = guess_suitable_icon
          args = ["notify-send",
                  "--expire-time", "5000",
                  "--urgency", urgency]
          args.concat(["--icon", icon.to_s]) if icon
          title = "%s [%g%%] (%gs)" % [@result.status,
                                       @result.pass_percentage,
                                       elapsed_time]
          args << title
          args << h(@result.summary)
          system(*args)
        end

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
