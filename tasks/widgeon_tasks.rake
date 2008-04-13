require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'ftools'

rails_root     = File.expand_path(RAILS_ROOT)
plugin_root    = File.join(rails_root, 'vendor', 'plugins', 'widgeon')
view_root      = File.join(rails_root, 'app', 'views')
widgets_root   = File.join(view_root, 'widgets')
templates_root = File.join(plugin_root, 'templates')
widgeon_views  = File.join(view_root, 'widgeon')

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
    File.install File.join(templates_root, 'widgeon_controller.rb'), File.join(rails_root, 'app', 'controllers')
    FileUtils.mkdir(widgeon_views) unless File.directory?(widgeon_views)
    File.install File.join(templates_root, 'callback.rjs'), widgeon_views
    File.install File.join(templates_root, 'widgeon.rb'), File.join(rails_root, 'config', 'initializers')
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