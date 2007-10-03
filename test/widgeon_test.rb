require 'test/test_helper'
require 'test/unit'
require 'fileutils'
require 'vendor/plugins/widgeon/test/test_helper'


class WidgeonTest < Test::Unit::TestCase
  include Widgeon
  
  def setup
    rails_root          = File.expand_path(RAILS_ROOT)
    @widgets_folder     = File.join(rails_root, 'widgets')
    @new_widgets_folder = File.join(rails_root, 'vendor', 'plugins', 'widgeon', 'test', 'fixtures')
    @hello_world_file   = File.join(@new_widgets_folder, 'hello_world_widget.rb')
    @loaded_widgets     = [:hello_world].to_set
  end
  
  def teardown
    Widget.widgets_folder = @widgets_folder
  end
  
  def test_widgets_module_definition
    assert defined?(ActionView::Helpers::Widgets)
  end
  
  def test_respond_to_widget_method
    assert ActionView::Helpers::Widgets.method_defined?(:widget)
  end
  
  def test_widget_class_definition
    assert defined?(Widget)
  end
  
  def test_widget_widgets_folder_set
    test_widget_widgets_folder
    
    Widget.widgets_folder = @new_widgets_folder
    assert_equal(@new_widgets_folder, Widget.widgets_folder)
  end
  
  def test_widget_widgets_folder
    assert_equal(@widgets_folder, Widget.widgets_folder)
  end
  
  def test_widget_widget_name
    Widget.widgets_folder = @new_widgets_folder
    assert_equal('hello_world', Widget.widget_name(@hello_world_file))
  end
  
  def test_widget_loaded_widgets
    test_widget_load_widgets

    assert_equal(@loaded_widgets, Widget.loaded_widgets)
  end
  
  def test_widget_load_widgets
    Widget.widgets_folder = @new_widgets_folder
    assert_nothing_raised(ArgumentError) { Widget.load_widgets }
  end
  
  def test_widget_defined
    test_widget_loaded_widgets
    
    Widget.widgets_folder = @new_widgets_folder
    assert Widget.widget_defined?(:hello_world)
    assert !Widget.widget_defined?(:unexistent)
  end
  
  def test_widget_initalize
    widget = HelloWorldWidget.new(:name => 'hello world')
    assert_equal('hello world', widget.name)
  end
end