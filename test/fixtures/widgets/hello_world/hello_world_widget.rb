class HelloWorldWidget < Widgeon::Widget
  
  # Test before render
  def before_render
    @greet = "Hello World!"
  end
  
  # For testing the session
  def session_set(value)
    widget_session[:test] = value
  end
  
  # For testing the session
  def session_get
    widget_session[:test]
  end
end