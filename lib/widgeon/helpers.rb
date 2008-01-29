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
    
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      widget_obj = @widget 
      options[:partial] = "widgets/#{@widget.class.widget_name}/#{partial}"
      options[:locals] = { :widget => @widget }
      result = render(options)
      # Restore the widget object. This is a "global variable" in this scope,
      # and if the render() rendered other widgets it will have been overwritten
      # TODO: Evil kludge, think about elegant solution
      @widget = widget_obj
      result
    end
    
    # Renders backlink to this widget, using a hidden form field. This will
    # call back to the original widget, with the callback_options passed to the
    # callback widget (available in before_render).
    #
    # In the callback widget, the property <tt>is_callback</tt> will be set 
    # to true automatically.
    #
    # You may pass the original call options for the current widget by passing
    # the option <tt>:default_options => true</tt>. Options in callback_options
    # will overwrite options with the same name.
    #
    # All options passed to a backlink must be serializable.
    def widget_backlink(text, callback_options)
      raise(ArgumentError, "Illegal options") unless(callback_options.is_a?(Hash))
      # Create the options 
      options = if(callback_options.delete(:default_options))
        @widget.call_options.merge(callback_options) # Add the default options
      else
        callback_options # Use just the callback options
      end
      
      "<div class='widget_backlink'>" +
        form_remote_tag(:url => { :controller => 'widgeon', :action => 'callback' }) +
        hidden_field_tag('widget_class', @widget.class.widget_name ) +
        hidden_field_tag('options', WidgeonEncoding.encode_object(options)) +
        submit_tag(text) +
        "</form></div>"
    end
    
    # It render the stylesheet for the current widget.
    #
    # <b>Convention:</b> The stylesheet must be in the same folder of the widget,
    # and it should be the same name.
    #
    # <b>Example:</b>
    #
    #   HelloWorld #=> hello_world.css
    #
    # <b>Usage:</b>
    #
    #  <%= stylesheet %>
    def stylesheet
      content_for(:stylesheet, %(<link href="/widgeon/stylesheet?widget=#{@widget.class.widget_name}" media="screen" rel="stylesheet" type="application/css" />))
    end
    
    private
    
    def render_widget
      @widget.render
      "<div id=\"#{@widget.id}\">#{render :partial => @widget.class.path_to_helper, :locals => { (@widget.class.widget_name+"_widget").to_sym => @widget }}</div>"
    end
  end
end
