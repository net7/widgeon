module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar') %>
    def widget(widget_name, options = {})
      options = options.merge(:controller => controller)
      @widget = Widget.load(widget_name.to_s).new(options)
      render_widget
    end
    
    # TODO merge with #widget
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      options[:partial] = "widgets/#{@widget.class.widget_name}/#{partial}"
      options[:locals] = { :widget => @widget }
      render(options)
    end
    
    # It render the stylesheet for the current widget.
    #
    # <b>Convention:</b> The stylesheet must be in the same folder of the widget,
    # and it should be the same name.
    #
    # <b>Example:</b>
    #
    #   HelloWorld #=> hello_world.css
    def stylesheet
      content_for(:stylesheet, %(<link href="/widget_proxy/stylesheet?widget=#{@widget.class.widget_name}" media="screen" rel="stylesheet" type="application/css" />))
    end
    
    private
    def render_widget
      @widget.render
      "<div id=\"#{@widget.id}\">#{render :partial => @widget.class.path_to_helper, :locals => { (@widget.class.widget_name+"_widget").to_sym => @widget }}</div>"
    end
  end
end
