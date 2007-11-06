class HelloWorldWidget < Widgeon::Widget
  
  # Test before render
  def before_render
    @new_option = "new option"
    @name = "after render"
  end
end