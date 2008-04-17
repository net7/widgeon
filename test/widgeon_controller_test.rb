require 'test/test_helper'

# Fake encoding class to check that the checksumming/digest works
class FakeEncoding < WidgeonEncoding
  def self.secret
    '12345'
  end
end

class WidgeonControllerTest < ActionController::TestCase
  
  def test_load_file
    get :load_file, :widgeon_id => 'asset_test', :file => 'stylesheets/style1.css'
    assert_response :success
  end
  
  def test_load_file_not_found
    assert_raises(Widgeon::ResourceNotFound) do 
      get :load_file, :widgeon_id => 'asset_test', :file => 'styleshets/style1.css'
    end
  end
  
  def test_ajax_callback_refresh
    enc_options = WidgeonEncoding.encode_options(:widget_class => 'hello_world', :widget_id => 'test', :refresh => :default)
    xhr :get, :callback, :call_options => enc_options
    assert_response :success
  end
  
  def test_ajax_callback_refresh_illegal
    enc_options = WidgeonEncoding.encode_options(:widget_class => 'hello_wor', :refresh => :default)
    assert_raises(ArgumentError) do
      xhr :get, :callback, :call_options => enc_options
    end
  end
  
  def test_digest_check
    enc_options = FakeEncoding.encode_options(:widget_class => 'hello_world', :refresh => :default)
    assert_raises(ArgumentError) do
      xhr :get, :callback, :call_options => enc_options
    end
  end
  
  def test_ajax_callback_javascript
    enc_options = WidgeonEncoding.encode_options(:widget_class => 'hello_world', :widget_id => 'test', :javascript => 'test_callback')
    xhr :get, :callback, :call_options => enc_options
    assert_response :success
  end
  
  def test_ajax_callback_javascript_unknown
    enc_options = WidgeonEncoding.encode_options(:widget_class => 'hello_world', :widget_id => 'test', :javascript => 'test_ups')
    assert_raises(ActionView::TemplateError) do
      xhr :get, :callback, :call_options => enc_options
    end
  end
  
  def test_callback_fallback
    redir_to = {:controller => 'widgeon', :action => 'load_file'}
    enc_options = WidgeonEncoding.encode_options(:widget_class => 'hello_world', :widget_id => 'default',
      :request_params => redir_to, :fallback_enabled => true)
    get :callback, :call_options => enc_options
    assert_redirected_to redir_to
  end
  
  def test_callback_fallback_not_allowed
    redir_to = {:controller => 'widgeon', :action => 'load_file'}
    enc_options = WidgeonEncoding.encode_options(:widget_class => 'hello_world', :widget_id => 'default',
      :request_params => redir_to, :fallback_enabled => false)
    assert_raises(RuntimeError) do
      get :callback, :call_options => enc_options
    end
  end
end
