# -*- ruby -*-

require 'rubygems'
gem 'test-unit'
require 'hoe'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))
require 'test/unit/notify'

Test::Unit.run = true

version = Test::Unit::Notify::VERSION
ENV["VERSION"] = version
Hoe.new('test-unit-notify', version) do |p|
  p.developer('Kouhei Sutou', 'kou@clear-code.com')

  p.rubyforge_name = "test-unit"

  p.extra_deps = ["test-unit"]
end

task :tag do
  message = "Released Test::Unit::Notify #{version}!"
  base = "svn+ssh://#{ENV['USER']}@rubyforge.org/var/svn/test-unit/extensions/test-unit-notify/"
  sh 'svn', 'copy', '-m', message, "#{base}trunk", "#{base}tags/#{version}"
end

# vim: syntax=Ruby
