class HelloWorldWidget < Widgeon::Widget
  
  # Test before render
  def before_render
    @greet = "Hello World!"
  end
end