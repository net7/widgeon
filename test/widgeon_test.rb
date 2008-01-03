require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'

Widgeon::Helpers.class_eval do
  def render(options = nil, &block)
    ActionView::Base.new(File.join(File.dirname(__FILE__), 'fixtures')).render(options, block)
  end
end

class WidgeonTest < Test::Unit::TestCase
  include Widgeon
  include ActionView::Helpers::Widgets
  
  def setup
    @path_to_widgets  = "app/views/widgets"
    @path_to_fixtures = File.join(File.dirname(__FILE__), 'fixtures', 'widgets')
    @path_to_helper   = File.join('widgets', 'hello_world', 'hello_world_widget.html.erb')
    
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_fixtures)
  end

  def test_widget_paths
    set_original_path
    assert_equal(@path_to_widgets, Widget.path_to_widgets)
  end
  
  def test_widgets_module_should_be_defined_in_actionview
    assert defined? ActionView::Helpers::Widgets
  end
  
  def test_widget
    assert_dom_equal %(<div id="hello_world"><p>Hello World!</p></div>), widget(:hello_world)
  end
    
  def test_exists
    assert !Widget.exists?(:unexistent)
    assert  Widget.exists?(:hello_world)
  end
  
  def test_load_should_fail_when_try_to_load_an_unexistent_widget
    assert_raise(ArgumentError) { Widget.load("unexistent") }
  end
  
  def test_should_load_widget
    assert defined? Widget.load("hello_world")
  end
  
  def test_initialize
    assert_equal 'Luca', Widget.new(:name => 'Luca').name
  end
  
  def test_widget_name
    assert_equal 'hello_world', Widget.load('hello_world').new.widget_name
  end
  
  def test_id_should_return_widget_name_if_not_explicitly_defined
    assert_equal 'hello_world', Widget.load('hello_world').new.id
  end
  
  def test_id
    assert_equal 'greetings', Widget.load('hello_world').new(:id => 'greetings').id
  end
  
  def test_path_to_helper
    assert_equal @path_to_helper, Widget.load('hello_world').new.path_to_helper
  end
  
  private
  def set_original_path
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_widgets)
  end
end