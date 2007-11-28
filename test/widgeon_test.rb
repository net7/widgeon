require 'test/test_helper'
require 'test/unit'
require 'fileutils'
require 'vendor/plugins/widgeon/test/test_helper'

class WidgeonController < ApplicationController
  def rescue_action(e) raise e end;
end
module WidgeonHelper; end

Widgeon::Widget.class_eval do
  def controller; @controller ||= WidgeonController.new end
  def request; @request ||= ActionController::TestRequest.new end
end

Widgeon::Helpers.class_eval do
  def controller; @controller = WidgeonController.new end
  def request; @request = ActionController::TestRequest.new end
  def render(options = nil, &block); end
end

class WidgeonTest < Test::Unit::TestCase
  include Widgeon
  include ActionView::Helpers::Widgets
  
  def setup
    rails_root            = File.expand_path(RAILS_ROOT)
    @widgets_folder       = File.join(rails_root, 'widgets')
    @test_widgets_folder  = File.join(rails_root, 'vendor', 'plugins', 'widgeon', 'test', 'fixtures')
    @hello_world_file     = File.join(@test_widgets_folder, 'hello_world_widget.rb')
    @path_to_self         = File.join('app', 'views', 'widgets', 'hello_world')
    @loaded_widgets       = [:hello_world, :configured].to_set
    @configuration        = {'host' => 'localhost', 'port' => 3000, 'path' => 'widgets'}
    @default_attributes   = [:request, :controller]
    Widget.widgets_folder = @test_widgets_folder
    
    @response = ActionController::TestResponse.new
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
  
  def test_widgets_folder_set
    Widget.widgets_folder = "new_path"
    assert_equal("new_path", Widget.widgets_folder)
  end
  
  def test_widgets_folder
    assert_equal(@test_widgets_folder, Widget.widgets_folder)
  end
  
  def test_path_to_self
    assert_equal(@path_to_self, HelloWorldWidget.new.path_to_self)
  end
  
  def test_loaded_widget
    Widget.load_widget('hello_world')
    assert_equal(Widget.loaded_widgets, @loaded_widgets)
  end
  
  def test_create_widget
    widget = Widget.create_widget('hello_world')
    assert(defined?(HelloWorldWidget))
    assert_kind_of(HelloWorldWidget, widget)
  end
  
  def test_load_widget_fail
    assert_raises(MissingSourceFile) { Widget.load_widget('hello_moon') }
  end
  
  def test_widget_defined
    Widget.load_widget('hello_world')
    
    assert Widget.widget_defined?(:hello_world)
    assert !Widget.widget_defined?(:unexistent)
  end
  
  def test_default_attributes
    assert_equal(@default_attributes, Widget.default_attributes)
  end
  
  def test_widget_name
    assert_equal('widget', Widgeon::Widget.widget_name)

    @loaded_widgets.each do |widget|
      widget = widget.to_s
      Widget.load_widget(widget)
      widget_klass = "#{widget}Widget".camelize.constantize
      assert_equal(widget, widget_klass.widget_name)
    end
  end
  
  def test_initalize
    widget = HelloWorldWidget.new(:name => 'hello world')
    assert_equal('hello world', widget.name)
    
    Widget.load_widget('configured')
    widget = ConfiguredWidget.new
    assert_equal(23, widget.simple_value)
    assert_equal(@configuration, widget.endpoint)
    key = widget.send(:session_key, true)
    assert widget.request.session[key].empty?
  end
  
  def test_before_render_call
    widget = Widget.create_widget(:hello_world, :name => 'hello world')
    widget.before_render_call
    assert_equal('after render', widget.name)
    assert_equal('new option', widget.new_option)
    key = widget.send(:session_key)
    assert_kind_of(Hash, widget.request.session[key])
    assert_kind_of(Hash, widget.request.session[key][:attributes])
    assert !widget.request.session[key][:attributes].empty?
  end
  
  def test_page_state
    widget = Widget.create_widget(:hello_world, :name => 'hello world')
    widget.before_render_call
    assert_equal(1, widget.page_state.size)
    widget.page_state[:page_stuff] = 'some bla bla'
    assert_equal('some bla bla', widget.page_state[:page_stuff])
    
    # another render
    widget.before_render_call
    assert_equal(1, widget.page_state.size)
  end
  
  def test_permanent_state
    widget = Widget.create_widget(:hello_world, :name => 'hello world')
    assert widget.permanent_state.empty?
    widget.before_render_call
    widget.permanent_state[:permanent_stuff] = 'some bla bla'
    assert_equal('some bla bla', widget.permanent_state[:permanent_stuff])
    
    # another render
    widget.before_render_call
    assert_equal('some bla bla', widget.permanent_state[:permanent_stuff])
    
    # explicit flush
    widget.clean_permanent_state
    assert widget.permanent_state.empty?
  end
  
  def test_create_page_state
    # without :identifier and clean session
    widget = Widget.create_widget(:hello_world)
    key = widget.send(:session_key)
    widget.send(:create_page_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert_kind_of(Hash, widget.request.session[key][:attributes])
    assert widget.request.session[key][:attributes].empty?
    
    # without :identifier with session
    widget.request.session[key] = { :plugin => 'widgeon' }
    assert_not_nil(widget.request.session[key])
    widget.send(:create_page_state)
    assert_kind_of(Hash, widget.request.session[key])
    
    # with :identifier and clean session
    widget = Widget.create_widget(:hello_world, :identifier => 'id')
    key = widget.send(:session_key)
    widget.send(:create_page_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert_kind_of(Hash, widget.request.session[key][:attributes])
    assert_equal(1, widget.request.session[key][:attributes].size)
    
    # with :identifier and with session
    widget.request.session[key] = { :plugin => 'widgeon' }
    assert_not_nil(widget.request.session[key])
    widget.send(:create_page_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert_equal(1, widget.request.session[key].size)
  end
  
  def test_create_permanent_state
    # without :identifier and clean session
    widget = Widget.create_widget(:hello_world)
    key = widget.send(:session_key, true)
    widget.send(:create_permanent_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert widget.request.session[key].empty?
    
    # without :identifier with session
    widget.request.session[key] = { :plugin => 'widgeon' }
    assert_not_nil(widget.request.session[key])
    widget.send(:create_permanent_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert widget.request.session[key].empty?
    
    # with :identifier and clean session
    widget = Widget.create_widget(:hello_world, :identifier => 'id')
    key = widget.send(:session_key, true)
    widget.send(:create_permanent_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert widget.request.session[key].empty?
    
    # with :identifier and with session
    widget.request.session[key] = { :plugin => 'widgeon' }
    assert_not_nil(widget.request.session[key])
    widget.send(:create_permanent_state)
    assert_kind_of(Hash, widget.request.session[key])
    assert widget.request.session[key].empty?    
  end
  
  def test_identification_key
    widget = Widget.create_widget(:hello_world)
    assert_equal(:widget_hello_world_default, widget.send(:identification_key))
    
    widget = Widget.create_widget(:hello_world, :identifier => 'id')
    assert_equal(:widget_hello_world_id, widget.send(:identification_key))
  end
  
  def test_session_key
    widget = Widget.create_widget(:hello_world)
    assert_equal(:widget_hello_world_default_page, widget.send(:session_key))

    assert_equal(:widget_hello_world_default_permanent, widget.send(:session_key, true))

    widget = Widget.create_widget(:hello_world, :identifier => 'id')
    assert_equal(:widget_hello_world_id_page, widget.send(:session_key))

    assert_equal(:widget_hello_world_id_permanent, widget.send(:session_key, true))
  end
  
  def ignore_test_helper_widget
    assert_raise(MissingSourceFile) { widget(:unexistent) }
    
    assert_nothing_raised(MissingSourceFile) { widget(:hello_world) }
  end
end