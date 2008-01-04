require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'

Widgeon::Helpers.class_eval do
  def render(options = nil, old_local_assigns = {}, &block)
    ActionView::Base.new(File.join(File.dirname(__FILE__), 'fixtures'), options[:locals]).render(options, &block)
  end
end

class WidgeonTest < Test::Unit::TestCase
  include Widgeon
  include ActionView::Helpers::Widgets
  
  def setup
    @path_to_widgets       = "app/views/widgets"
    @path_to_fixtures      = File.join(File.dirname(__FILE__), 'fixtures', 'widgets')
    @path_to_helper        = File.join('widgets', 'hello_world', 'hello_world_widget.html.erb')
    @path_to_configuration = File.join(@path_to_fixtures, 'hello_world', 'hello_world.yml')
    
    @callbacks = [ :before_render ]
    
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_fixtures)
  end

  def test_widget_paths
    set_original_path
    assert_equal(@path_to_widgets, Widget.path_to_widgets)
  end
  
  def test_callbacks
    assert_equal @callbacks, Widget.callbacks
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
    assert defined? hello_world
  end
  
  def test_configuration_loading_should_be_skipped_for_not_existent_file
    assert_equal [], hello_world.instance_variables
  end
  
  def test_configuration_should_be_loaded_if_file_is_present
    assert_equal 23, Widget.load('configured').new.number
  end
  
  def test_initialize
    assert_equal 'Luca', Widget.new(:name => 'Luca').name
  end
  
  def test_widget_name
    assert_equal 'hello_world', hello_world.class.widget_name
  end
  
  def test_id_should_return_widget_name_if_not_explicitly_defined
    assert_equal 'hello_world', hello_world.id
  end
  
  def test_id
    assert_equal 'greetings', hello_world(:id => 'greetings').id
  end
  
  def test_path_to_helper
    assert_equal @path_to_helper, hello_world.class.path_to_helper
  end
  
  def test_path_to_configuration
    assert_equal @path_to_configuration, hello_world.class.path_to_configuration
  end
  
  def test_create_instance_accessors_from_attributes
    hello_world.instance_variable_set(:@italian_greet, "Ciao Mondo!")
    @hello_world.send :create_instance_accessors_from_attributes
    assert_equal "Ciao Mondo!", @hello_world.italian_greet
  end
  
  def test_call_callbacks_chain
    hello_world.send :call_callbacks_chain
    assert_equal "Hello World!", @hello_world.instance_variable_get(:@greet)
  end
  
  private
  def set_original_path
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_widgets)
  end
  
  def hello_world(params = {})
    @hello_world = Widget.load('hello_world').new(params)
  end
end