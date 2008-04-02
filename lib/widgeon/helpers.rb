module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar') %>
    def widget(widget_name, options = {})
      widget = Widget.load_widget(widget_name.to_s).new(controller, request, options)
      widget.render(self)
    end
    
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      w.render_template(self, partial, options)
    end
    
    
    # Create a remote link to a widget. A remote link will be send through an
    # remote call to the widget engine. All options that are not used
    # for creating the remote link will be available to the widget in the
    # remote call.
    # 
    # The widget in the remote call will have all properties that are
    # in the widget's configuration file, but all other parameters needed for
    # the remote operation must be passed through the options hash. 
    # 
    # == Rendering modes
    # 
    # At the moment there are two modes for remote links
    # 
    # * <tt>:refresh</tt> - Replace the widget's content (that is, the
    #   content of the widget's <div> element with the given template. If
    #   <tt>:refresh => :default</tt> is given, this will render the widget's
    #   default template
    # * <tt>:javascript</tt> - Will use a javascript handler to modify the page.
    #   The javascript handler must be defined within the widget.
    # 
    # == Fallback
    # 
    # The <tt>:fallback</tt> option may be an URL string or an <tt>url_for</tt>
    # hash may be given. This will be set as the <tt>href</tt> of the link and
    # will be used in case javascript is disabled in the browser.
    # 
    # Alternatively, the <tt>:fallback</tt> option may be set to
    # <tt>:fallback => :reload</tt>. This will cause the link to be directed
    # to the widget system. The widget system will reload the page, and all
    # widgets on the page will be set up for the "callback" mode. The "current"
    # widget will receive the option hash from the remot link when the page
    # is reloaded.
    # 
    # By passing false to the fallback parameter, the mechanism will be disabled.
    # 
    # By default the remote link will use the "<tt>:reload</tt>" mechanism
    # for template rendering, and no fallback for
    # javascript renderers.
    # 
    # == Default options
    # 
    # If the option <tt>:default_options => true</tt> is used, the callback
    # will include the options that were passed to the widget during it's 
    # initialization
    # 
    # == Examples
    #
    #  widget_remote_link("foo", :refresh => :default, :static_url => "http://foo")
    #  widget_remote_link("foobar", :refresh => "my_template", :fallback => false)
    #  widget_remote_link("bar", :javascript => :my_handler, :my_option => "now")
    def widget_remote_link(name, options, html_options = {})
      prepare_options!(options)
      fallback_uri = prepare_fallback_uri!(options)
      html_options[:href] = fallback_uri
      
      link_to_remote(name, 
        { :url => { :controller => "widgeon", 
            :action => "remote_call", 
            :call_options => WidgeonEncoding.encode_options(options) 
          } },
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
    def prepare_options!(options)
      raise(ArgumentError, "Illegal options") unless(options.is_a?(Hash))
      raise(ArgumentError, "Must give either the :refresh or the :javascript option") unless(options[:refresh] || options[:javascript])
      
      # Update the fallback option
      unless(options.has_key?(:fallback)) # See if fallback is set by the user
         options[:fallback] = (options[:refresh] ? :reload : false) # determine the default
      end
      
      if(options.delete(:default_options))
        options.merge(w.call_options) # Add the default options
      end
      
      # Add the URI to the widget
      options[:widget_class] = w.class.widget_name
      options[:widget_id] = w.id
      # The request params are only needed when the page is reloaded from the fallback
      options[:request_params] = w.request.parameters if(options[:fallback] == :reload)
      options
    end
    
    # Creates the fallback link from the option hash, and modifies the option
    # hash accordingly.
    def prepare_fallback_uri!(options)
      fallback_option = options[:fallback]
      fallback_url = ""
      
      # Now we create the URL that is used for the fallback
      case fallback_option
      when :reload # Create the linkback to the widget system
        options[:fallback_enabled] = true
        fallback_url = url_for(:controller => "widgeon", 
          :action => "remote_call", 
          :call_options => WidgeonEncoding.encode_options(options))
        options.delete(:fallback_enabled) # We don't need this any further
      when false, nil
        fallback_url = '#'
      else
        if(fallback_option.is_a?(Hash))
          fallback_url = url_for(fallback_option)
        else
          fallback_url = fallback_option
        end
      end
      
      fallback_url
    end
    
  end
end
