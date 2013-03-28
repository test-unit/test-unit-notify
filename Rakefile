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
require "packnga"
require 'rubygems'
require "bundler/gem_helper"

helper = Bundler::GemHelper.new(base_dir)
def helper.version_tag
  version
end

helper.install
spec = helper.gemspec
version = spec.version

Packnga::DocumentTask.new(spec) do |task|
  task.original_language = "en"
  task.translate_language = "ja"
end

Packnga::ReleaseTask.new(spec) do |task|
end

namespace :doc do
  task :screenshot do
    doc_dir = base_dir + "doc"
    reference_dir = doc_dir + "reference"
    reference_screenshot_dir = reference_dir + "screenshot"
    mkdir_p(reference_screenshot_dir.to_s)
    (base_dir + "screenshot").children.each do |file|
      next if file.directory?
      cp(file.to_s, reference_screenshot_dir.to_s)
    end
  end
end
task :yard => "doc:screenshot"

# vim: syntax=Ruby
