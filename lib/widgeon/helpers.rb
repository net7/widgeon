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
      
      # Add the URI to the widget
      options[:widget_class] = @widget.class.widget_name
      
      "<div class='widget_backlink'>" +
        form_remote_tag(:url => { :controller => "widgeon", :action => 'callback'} ) +
        hidden_field_tag('widget_callback_options', WidgeonEncoding.encode_options(options)) +
        submit_tag(text) +
        "</form></div>"
    end
    
    private
    
    def render_widget
      @widget.render
      widget_content = render(:partial => @widget.class.path_to_helper, 
                              :locals => { (@widget.class.widget_name+"_widget").to_sym => @widget })
      "#{inline_style}\n<div id=\"#{@widget.id}\">#{widget_content}</div>"
    end
    
    # Helper that returns the "inline style" for the widget. This will return
    # a <style> tag to be included in the HTML if the widget has a stylesheet
    # *and* if the <tt>inline_styles</tt> property of the Widget engine is true
    def inline_style
      style = ""
      if(@widget.class.inline_styles && (w_style = @widget.class.widget_style))
        style = "<style type='text/css'><!--\n#{w_style}\n--></style>"
      end
      style
    end
    
  end
end
