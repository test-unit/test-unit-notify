# -*- mode: ruby; coding: utf-8 -*-

require "./lib/test/unit/notify/version"

clean_white_space = lambda do |entry|
  entry.gsub(/(\A\n+|\n+\z)/, '') + "\n"
end

version = Test::Unit::Notify::VERSION.dup

readme = File.read("README.md")
readme.force_encoding("UTF-8") if readme.respond_to?(:force_encoding)
entries = readme.split(/^##\s(.*)$/)
summary = clean_white_space.call(entries[entries.index("DESCRIPTION") + 1])
summary = summary.gsub(/^test-unit-notify\s*-\s*/, "")
features_entry = entries[entries.index("FEATURES") + 1]
features = clean_white_space.call(features_entry).gsub(/^\*\s+/, "")
description = summary + features

Gem::Specification.new do |spec|
  spec.name = "test-unit-notify"
  spec.version = version
  spec.homepage = "https://github.com/test-unit/test-unit-notify"
  spec.authors = ["Kouhei Sutou"]
  spec.email = ["kou@clear-code.com"]
  spec.summary = summary
  spec.description = description
  spec.license = "LGPLv2.1 or later"
  spec.files = ["README.md", "Rakefile", "Gemfile"]
  spec.files += [".yardopts"]
  spec.files += Dir.glob("{data,screenshot}/**/*.png")
  spec.files += Dir.glob("lib/**/*.rb")
  spec.files += Dir.glob("doc/text/*")

  spec.add_runtime_dependency("test-unit", ">= 2.4.9")
  spec.add_development_dependency("bundler")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("yard")
  spec.add_development_dependency("packnga")
  spec.add_development_dependency("kramdown")
end
