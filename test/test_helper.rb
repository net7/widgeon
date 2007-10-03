plugin_root = File.join(RAILS_ROOT, 'vendor', 'plugins', 'widgeon')
Dir["#{File.join(plugin_root, 'test', 'fixtures')}/*.rb"].each {|file| require file}