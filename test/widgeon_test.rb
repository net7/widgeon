require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'

class WidgeonTest < Test::Unit::TestCase
  include Widgeon

  def setup
    @path_to_widgets = "app/views/widgets"
  end

  def teardown
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_widgets)
  end

  def test_widget_paths
    assert_equal(@path_to_widgets, Widget.path_to_widgets)
  end
    
  def test_exists
    set_fixtures_folder
    assert !Widget.exists?(:unexistent)
    assert  Widget.exists?(:hello_world)
  end
  
  def test_load
    set_fixtures_folder
    assert_raise(ArgumentError) { Widget.load("unexistent") }

    Widget.load("hello_world")
    assert defined? HelloWorldWidget
  end
  
  def test_initialize
    assert_equal 'Luca', Widget.new(:name => 'Luca').name
  end
  
  private
  def set_fixtures_folder
    Widget.send(:class_variable_set, :@@path_to_widgets, File.join(File.dirname(__FILE__), 'fixtures'))
  end
end