plugin_root = File.join(RAILS_ROOT, 'vendor', 'plugins', 'widgeon')
Dir["#{File.join(plugin_root, 'test', 'fixtures')}/*.rb"].each {|file| require file}

# Small hack to the widgeon plugin to pickup the fixtures directory.
Widgeon.const_set(:WIDGEON_ROOT, File.join(File.dirname(__FILE__), 'fixtures', 'widgets'))
# Same for the public asset path
Widgeon.const_set(:WIDGEON_PUBLIC_ASSETS, File.join(File.dirname(__FILE__), 'temp_asset_test'))