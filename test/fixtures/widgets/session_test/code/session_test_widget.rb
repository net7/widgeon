class SessionTestWidget < Widgeon::Widget
  
  def session_put(value)
    widget_session[:test] = value
  end
  
  def session_get
    widget_session[:test]
  end
end
