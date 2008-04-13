require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'
require 'fileutils'

class WidgeonTest < Test::Unit::TestCase
  
  include Widgeon
  
  def setup
    @request = ActionController::TestRequest.new
    @controller = ApplicationController.new
    @controller.request = @request
    @view = ActionView::Base.new([ File.join(File.dirname(__FILE__), 'fixtures') ], {}, @controller)
    @response = ActionController::TestResponse.new
    
    @hello = Widget.load_widget('hello_world')
    @hello_instance = @hello.new(@view, :my_option => "set")
    
    @assets = Widget.load_widget('asset_test')
    # This evil little trick clears the setup "by hand" so that we can test it
    # without setting up a dozend test classes
    @assets.instance_variable_set(:@stylesheets, nil)
    @assets.instance_variable_set(:@style_config, nil)
    @assets.instance_variable_set(:@javascripts, nil)
    @assets.instance_variable_set(:@js_config, nil)
    
  end
    
  def test_exists
    assert !Widget.exists?(:unexistent)
    assert  Widget.exists?(:hello_world)
  end
  
  def test_fail_for_unexisting
    assert_raise(ArgumentError) { Widget.load_widget("unexistent") }
  end
    
  def test_configuration_file_load
    widget = Widget.load_widget('configured').new(@view)
    assert_equal(23, widget.number)
  end
  
  def test_option
    assert_equal "set", @hello_instance.my_option
  end
  
  def test_widget_name
    assert_equal 'hello_world', @hello.widget_name
  end
  
  def test_id_should_return_widget_name_if_not_explicitly_defined
    assert_equal 'default', @hello_instance.id
  end
  
  def test_id
    widget = @hello.new(@view, :id => 'greetings')
    assert_equal 'greetings', widget.id
  end
 
  def test_create_instance_accessors_from_attributes
    widget = @hello.new(@view)
    widget.instance_variable_set(:@italian_greet, "Ciao Mondo!")
    widget.send :create_instance_accessors_from_attributes
    assert_equal "Ciao Mondo!", widget.italian_greet
  end
  
  def test_on_init
    assert_equal "Hello World!", @hello_instance.greet
  end
  
  def test_widget_session
    widget = Widget.load_widget('session_test').new(@view)
    widget.session_put('test the world')
    assert_equal 'test the world', widget.session_get
  end
  
  def test_javascript_all_by_default
    assert_equal ['script1', 'script2', 'script3'].sort, @assets.javascripts.sort
  end

  def test_javascript_with_select
    @assets.send(:script, 'script1.js', 'script2')
    assert_equal ['script1', 'script2'].sort, @assets.javascripts.sort
  end
  
  def test_stylesheets_all_by_default
    assert_equal ['style1', 'style2', 'style3'].sort, @assets.stylesheets.sort
  end
  
  def test_stylesheets_with_select
    @assets.send(:style, 'style1.css', 'style2')
    assert_equal ['style1', 'style2'].sort, @assets.stylesheets.sort
  end
  
  def test_list_widgets
    assert_equal ['asset_test', 'configured', 'hello_world', 'session_test'].sort, Widget.list_widgets.sort
  end
  
  def test_stylesheet
    @assets.send(:style, 'style1.css')
    comp = File.open(File.join(@assets.path_to_stylesheets, 'style1.css')) { |f| f.read }
    assert_equal comp, @assets.widget_style
  end
  
  def test_asset_installation
    assert_not_nil RAILS_ROOT, "Cannot run this without RAILS_ROOT"
    FileUtils.remove_dir(WIDGEON_PUBLIC_ASSETS, true)
    assert !File.exists?(File.join(WIDGEON_PUBLIC_ASSETS, 'asset_test', 'javascripts', 'script1.js'))
    Widget.asset_mode = :install # should cause the install
    assert File.exists?(File.join(WIDGEON_PUBLIC_ASSETS, 'asset_test', 'javascripts', 'script1.js'))
    assert File.exists?(File.join(WIDGEON_PUBLIC_ASSETS, 'asset_test'))
    FileUtils.remove_dir(WIDGEON_PUBLIC_ASSETS, true)
  end
  
  def test_render
    assert_dom_equal %(<div id="hello_world-default"><p>Hello World!</p></div>), @hello_instance.render
  end
  
  def test_partial
    assert_dom_equal %(<b>I am a partial for a widget</b>\n), @hello_instance.partial('hello_partial')
  end
 
end