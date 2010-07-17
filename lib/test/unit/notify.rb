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
      VERSION = "0.0.1"

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
            notify_by_notify_send
          end
        end

        def notify_by_notify_send
          icon = guess_suitable_icon
          args = ["notify-send",
                  "--expire-time", "5000",
                  "--urgency", urgency]
          args.concat(["--icon", icon.to_s]) if icon
          args.concat([@result.status, h(@result.summary)])
          system(*args)
        end

        def guess_suitable_icon
          icon_dir = ICON_DIR + @theme
          icon = icon_dir + "#{@result.status}.png"
          if !icon.exist? and @result.passed?
            icon = icon_dir + "success.png"
          end
          icon = icon_dir + "default.png" unless icon.exist?
          return nil unless icon.exist?
          icon
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
