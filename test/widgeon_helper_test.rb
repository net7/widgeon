require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'
require 'fileutils'

class WidgeonHelperTest < Test::Unit::TestCase
  
  include Widgeon
  
  def setup
    @request = ActionController::TestRequest.new
    @controller = ApplicationController.new
    @controller.request = @request
    @view = ActionView::Base.new([ File.join(File.dirname(__FILE__), 'fixtures') ], {}, @controller)
    @response = ActionController::TestResponse.new
    
    @hello = Widget.load_widget('hello_world')
    @hello_instance = @hello.new(@view, :my_option => "set")
    @view.current_widget = @hello_instance # Needed for the "inside" helpers that get the w. property from the view
  end
  
  def test_widget
    assert_dom_equal %(<div id="hello_world-default"><p>Hello World!</p></div>), @view.widget(:hello_world)
    # Assert if the auto widget was set
    assert @view.instance_variable_get(:@auto_widgets).include?(:hello_world)
  end
  
  def test_style_links
    assert_dom_equal "<link href=\"/widgeon/asset_test/stylesheets/style1.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n<link href=\"/widgeon/asset_test/stylesheets/style2.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n<link href=\"/widgeon/asset_test/stylesheets/style3.css\" rel=\"stylesheet\" type=\"text/css\" media=\"screen\" />\n",
      @view.widget_stylesheet_links(:all)
  end

  def test_script_links
    assert_dom_equal "<script src=\"/widgeon/asset_test/javascripts/script1.js\" type=\"text/javascript\"></script>\n<script src=\"/widgeon/asset_test/javascripts/script2.js\" type=\"text/javascript\"></script>\n<script src=\"/widgeon/asset_test/javascripts/script3.js\" type=\"text/javascript\"></script>\n",
      @view.widget_javascript_links(:all)
  end
end
