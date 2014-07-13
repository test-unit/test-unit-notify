# -*- ruby -*-

require "pathname"

base_dir = Pathname(__FILE__).dirname.expand_path
test_unit_dir = (base_dir.parent + "test-unit").expand_path
test_unit_lib_dir = test_unit_dir + "lib"
lib_dir = base_dir + "lib"

$LOAD_PATH.unshift(test_unit_lib_dir.to_s)
$LOAD_PATH.unshift(lib_dir.to_s)

require "test/unit/notify"

require "yard"
require "packnga"
require "rubygems"
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

release_task = nil
Packnga::ReleaseTask.new(spec) do |task|
  release_task = task
  task.index_html_dir = "../../www/test-unit.github.io"
end

doc_dir = base_dir + "doc"
reference_dir = doc_dir + "reference"
reference_screenshot_dir = reference_dir + "screenshot"
namespace :doc do
  directory reference_screenshot_dir.to_s
  task :screenshot => reference_screenshot_dir.to_s do
    (base_dir + "screenshot").children.each do |file|
      next if file.directory?
      cp(file.to_s, reference_screenshot_dir.to_s)
    end
  end
end
task :yard => "doc:screenshot"

namespace :release do
  namespace :references do
    namespace :upload do
      index_html_dir = release_task.instance_variable_get(:@index_html_dir)
      index_html_dir = Pathname.new(index_html_dir)
      upload_dir = index_html_dir + spec.name
      directory upload_dir.to_s
      task :screenshot => ["doc:screenshot", upload_dir.to_s] do
        cp_r(reference_screenshot_dir.to_s, upload_dir.to_s)
      end
    end
    task :upload => "upload:screenshot"
  end
end

# vim: syntax=Ruby
