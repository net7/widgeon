module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar') %>
    def widget(widget_name, options = {})
      widget = Widget.load(widget_name.to_s).new(controller, request, options)
      widget.render(self)
    end
    
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      w.render_template(self, partial, options)
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
      prepare_options(callback_options)
      
      "<div class='widget_backlink'>" +
        form_remote_tag(:url => { :controller => "widgeon", :action => 'callback'} ) +
        hidden_field_tag('widget_callback_options', WidgeonEncoding.encode_options(options)) +
        submit_tag(text) +
        "</form></div>"
    end
    
    # This inserts a remote link into the widget. When the link is called, an
    # instance of the widget will be created and the given <tt>remote_call</tt>
    # action will be executed on the widget object
    def widget_remotelink(text, template, options, html_options = nil)
      prepare_options(options)
      options.delete(:request_params) # We don't really need them here
      options[:template] = template
      
      link_to_remote(text, 
        { :url => { :controller => "widgeon", :action => "remote_call", :call_options => WidgeonEncoding.encode_options(options) } },
        html_options )
    end
    
    # This is a special helper which returns the widget object for the 
    # current view.
    def w
      @widget # Return the widget object which has been injected into the view.
    end
    
    # Used to inject the current widget into the view
    def current_widget=(widget)
      @widget = widget
    end
    
    private
    
    # Prepare an option hash for the current widget, to be used with AJAX 
    # callbacks
    def prepare_options(options)
      raise(ArgumentError, "Illegal options") unless(options.is_a?(Hash))
      # Create the options 
      if(options.delete(:default_options))
        options.merge(@widget.call_options) # Add the default options
      end
      
      # Add the URI to the widget
      options[:widget_class] = @widget.class.widget_name
      options[:widget_id] = @widget.id
      options[:request_params] = @widget.request.parameters
      options
    end
    
  end
end
