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
    AutoRunner.setup_option do |auto_runner, options|
      options.on("--[no-]notify",
                 "Notify test result at the last.") do |use_notify|
        auto_runner.listeners.reject! do |listener|
          listener.is_a?(Notify::Notifier)
        end
        auto_runner.listeners << Notify::Notifier.new if use_notify
      end
    end

    module Notify
      VERSION = "0.0.2"

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
