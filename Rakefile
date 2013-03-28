# -*- ruby -*-

require 'pathname'

base_dir = Pathname(__FILE__).dirname.expand_path
test_unit_dir = (base_dir.parent + "test-unit").expand_path
test_unit_lib_dir = test_unit_dir + "lib"
lib_dir = base_dir + "lib"

$LOAD_PATH.unshift(test_unit_lib_dir.to_s)
$LOAD_PATH.unshift(lib_dir.to_s)

require 'test/unit/notify'

require "yard"
require 'rubygems'
require "bundler/gem_helper"

helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec
version = spec.version

YARD::Rake::YardocTask.new do |task|
end

namespace :doc do
task :screenshot do
  doc_dir = base_dir + "doc"
  doc_screenshot_dir = doc_dir + "screenshot"
  mkdir_p(doc_screenshot_dir.to_s)
  (base_dir + "screenshot").children.each do |file|
    next if file.directory?
    cp(file.to_s, doc_screenshot_dir.to_s)
  end
end
end
task :yard => "doc:screenshot"

task :tag do
  message = "Released Test::Unit::Notify #{version}!"
  sh 'git', 'tag', '-a', version, '-m', message
end

# vim: syntax=Ruby
