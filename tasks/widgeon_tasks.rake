require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'fileutils'

rails_root	 = File.expand_path(RAILS_ROOT)
plugin_root	 = File.join(rails_root, 'vendor', 'plugins', 'widgeon')
widgets_root = File.join(rails_root, 'vendor', 'widgets')

desc "Default task for widgeon plugin (test task)."
task :widgeon => :default

desc "Default task for widgeon plugin (test task)."
task :default => 'widgeon:test'

namespace :widgeon do
  desc "Test wigeon plugin."
  Rake::TestTask.new(:test) do |t|
	  t.libs << "#{plugin_root}/lib"
	  t.pattern = "#{plugin_root}/test/**/*_test.rb"
	  t.verbose = true
  end
  
  desc "Setup the widgeon plugin (alias for install)."
  task :setup => :install

  desc "Install the widgeon plugin."
  task :install do
    FileUtils.mkdir(widgets_root) unless File.directory?(widgets_root)
  end
  
  desc 'Generate documentation for the widgeon plugin.'
  Rake::RDocTask.new(:rdoc) do |rdoc|
  	rdoc.rdoc_dir = "#{plugin_root}/rdoc"
  	rdoc.title		= 'Widgeon'
  	rdoc.options << '--line-numbers' << '--inline-source'
  	rdoc.rdoc_files.include("#{plugin_root}/README")
  	rdoc.rdoc_files.include("#{plugin_root}/lib/**/*.rb")
  end
end