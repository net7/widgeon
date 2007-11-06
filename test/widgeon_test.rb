require 'test/test_helper'
require 'test/unit'
require 'fileutils'
require 'vendor/plugins/widgeon/test/test_helper'

class WidgeonController < ApplicationController
  def rescue_action(e) raise e end;
end
module WidgeonHelper; end

Widgeon::Helpers.class_eval do
  def controller; @controller = WidgeonController.new end
  def request; @request = ActionController::TestRequest.new end
#  def render(options = nil, &block); ActionController::Base.send(:render, options, &block) end
  def render(options = nil, &block); end
end

class WidgeonTest < Test::Unit::TestCase
  include Widgeon
  include ActionView::Helpers::Widgets
  
  def setup
    rails_root            = File.expand_path(RAILS_ROOT)
    @widgets_folder       = File.join(rails_root, 'widgets')
    @views_folder         = File.join('app', 'views', 'widgets')
    @test_widgets_folder  = File.join(rails_root, 'vendor', 'plugins', 'widgeon', 'test', 'fixtures')
    @hello_world_file     = File.join(@test_widgets_folder, 'hello_world_widget.rb')
    @loaded_widgets       = [:hello_world].to_set
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

  def test_views_folder
    assert_equal(@views_folder, Widget.views_folder)
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
  
  def test_initalize
    widget = HelloWorldWidget.new(:name => 'hello world')
    assert_equal('hello world', widget.name)
  end
  
  def test_before_render_call
    widget = Widget.create_widget(:hello_world, :name => 'hello world')
    widget.before_render_call
    assert_equal('after render', widget.name)
    assert_equal('new option', widget.new_option)
  end
  
  def test_helper_widget
    assert_raise(MissingSourceFile) { widget(:unexistent) }
    
    assert_nothing_raised(MissingSourceFile) { widget(:hello_world) }
  end
end