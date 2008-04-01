require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'

class WidgeonTestController < ApplicationController
  def rescue_action(e) raise e end;
end
module WigeonTestHelper; end

# Injects a controller into the helpers that will work with the tests and modify
# the render method to use the new path
Widgeon::Helpers.class_eval do
  attr_accessor_with_default :controller, WidgeonTestController.new
  attr_accessor_with_default :request, ActionController::TestRequest.new
  def render(options = nil, old_local_assigns = {}, &block)
    options[:locals] ||= {}
    view = ActionView::Base.new(File.join(File.dirname(__FILE__), 'fixtures'), options[:locals])
    # Transfer the widget variable... don't ask
    # This is because of the weirdness of this test: The widget itself will
    # think that the test class is the "view" - while the widget template
    # will use the view object we just created...
    # TODO: Fix this #%$@#% test
    view.instance_variable_set(:@widget, @widget)
    view.render(options, old_local_assigns, &block)
    
  end
end

class WidgeonTest < Test::Unit::TestCase
  include Widgeon
  include ActionView::Helpers::Widgets
  
  def setup
    @path_to_widgets       = "app/views/widgets"
    @path_to_fixtures      = File.join(File.dirname(__FILE__), 'fixtures', 'widgets')
    @path_to_template        = File.join('widgets', 'hello_world', 'hello_world_widget')
    @path_to_self          = File.join(@path_to_fixtures, 'hello_world')
    @path_to_configuration = File.join(@path_to_self, 'hello_world.yml')
    @path_to_helpers       = File.join(@path_to_fixtures, 'helping', 'helping_helper.rb')
    
    @callbacks = [ :before_render ]
    @widgets   = %w( helping configured hello_world )
    
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_fixtures)
  end

  def test_widget_paths
    set_original_path
    assert_equal(@path_to_widgets, Widget.path_to_widgets)
  end
  
  def test_callbacks
    assert_equal @callbacks, Widget.callbacks
  end
  
  def test_loaded_widgets
    assert_equal @widgets, Widget.loaded_widgets.keys
  end
  
  def test_widgets_module_should_be_defined_in_actionview
    assert defined? ActionView::Helpers::Widgets
  end
  
  def test_widget
    assert_dom_equal %(<div id="hello_world-default"><p>Hello World!</p></div>), widget(:hello_world)
  end
    
  def test_should_have_a_controller_as_instance_variable
    assert_kind_of(WidgeonTestController, hello_world.controller)
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
    
  def test_configuration_loading_should_be_skipped_for_not_existing_file
    assert_equal ["@call_options", "@id", "@request", "@created_instance_vars", "@controller"].sort, hello_world.instance_variables.sort
  end
  
  def test_configuration_should_be_loaded_if_file_is_present
    assert_equal 23, configured.new(controller, request).number
  end
  
  def test_initialize
    assert_equal 'Luca', Widget.new(controller, request, :name => 'Luca').name
  end
  
  def test_widget_name
    assert_equal 'hello_world', hello_world.class.widget_name
  end
  
  def test_id_should_return_widget_name_if_not_explicitly_defined
    assert_equal 'default', hello_world.id
  end
  
  def test_id
    assert_equal 'greetings', hello_world(:id => 'greetings').id
  end
  
  def test_path_to_self
    assert_equal @path_to_self, hello_world.class.path_to_self
  end
  
  def test_path_to_template
    assert_equal @path_to_template, hello_world.class.path_to_template
  end
  
  def test_path_to_helpers
    assert_equal @path_to_helpers, helping.class.path_to_helpers
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
  
  def test_widget_session
    hello = hello_world
    assert_nil(hello.session_get)
    hello.session_set("test")
    assert_equal("test", hello.session_get)
  end
  
  def test_helper_include
    helping # load the widget
    assert(ActionView::Base.instance_methods.include?("the_helper_method"))
  end
  
  private
  def set_original_path
    Widget.send(:class_variable_set, :@@path_to_widgets, @path_to_widgets)
  end
  
  def hello_world(params = {})
    @hello_world = Widget.load('hello_world').new(controller, request, params)
  end
  
  def helping(params = {})
    @helping = Widget.load('helping').new(controller, request, params)
  end
  
  def configured
    Widget.load('configured')
  end
  
end