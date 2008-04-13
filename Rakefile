require 'rake'
require 'rake/gempackagetask'

task :cruise do
  puts 'Dummy task for cruise control.'
end

gem_spec = Gem::Specification.new do |spec|
  spec.name = "widgeon"
  spec.version = "0.0.1"
  spec.author = "Luca Guidi and Daniel Hahn"
  spec.email = ""
  spec.homepage = "http://talia.discovery-project.eu/"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "Widgets for Rails."
  spec.files = FileList["{lib}/**/*"].to_a
  spec.require_path = "lib"
  spec.test_files = FileList["{test}/**/*.rb"].to_a
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_tar = false # was true
end