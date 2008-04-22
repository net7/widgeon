module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # There are some special options that are recognized by the widget system.
    # Also note that the names <tt>:view</tt>, <tt>:controller</tt> and 
    # <tt>:request</tt> are protected, as well as all method names that already
    # exist on the Widget class.
    # 
    # * <tt>:widget_id</tt>  or <tt>:id</tt> - A string that uniquely identifies
    #   the widget instances. Only widgets with an id can use remote links.
    # * <tt>:html_options</tt> - a hash of options that will be used on the 
    #   widget's <div> tag.
    # 
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar') %>
    def widget(widget_name, options = {})
      widget = Widget.load_widget(widget_name.to_s).new(self, options)
      @auto_widgets ||= []
      @auto_widgets << widget_name # add to the list of already rendered widgets
      widget.render
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
    
    # Adds stylesheet links for the configured widgets. This can take the 
    # special values <tt>:all</tt> or <tt>:auto</tt> or a list of widget names. 
    #
    # The <tt>:auto</tt> value may be used in a layout and will automatically
    # pick up all widgets that are render in templates using that layout. It
    # will not pick up widgets that are used in the layout itself. <tt>:auto</tt>
    # can be combined with a list of widget names that are passed manually.
    # 
    # <tt>:all</tt> will load the sheets for *all* widgets that are installed
    # on the system. To do so, it will perform a one-time scan of the widget
    # directory.
    # 
    # The default value is <tt>:auto</tt>
    #
    # The result will be cached in the fragment cache. Calling this method 
    # disables inline rendering of styles!
    def widget_stylesheet_links(*widgets)
      Widgeon::Widget.inline_styles = false
      loop_for_widgets('widgeon/style_headers', *widgets) do |widget|
        collect_strings_from(widget.stylesheets) do |style|
          widget_stylesheet_link(widget, style)
        end
      end
    end
    
    # This is basically the same as widget_style_links, but for javascripts.
    def widget_javascript_links(*widgets)
      loop_for_widgets('widgeon/script_headers', *widgets) do |widget|
        collect_strings_from(widget.javascripts) do |script|
          widget_javascript_link(widget, script)
        end
      end
    end
    
    
    private
    
    # Creates a stylesheet link for a single widget stylesheet. This takes
    # the name of the widget and the name of the stylesheet.
    def widget_stylesheet_link(widget, style)
      if(Widgeon::Widget.asset_mode == :widget)
        # Use the home-brew link to the widget system
        link = '<link href="'
        link << '/widgeon/' << widget.widget_name
        link << '/stylesheets/' << style << '.css" '
        link << 'media="screen" rel="stylesheet" type="text/css" />'
        link << "\n"
        link
      else
        # use default stylesheet helpers
        stylesheet_link_tag(widget.web_path_to_public + "/stylesheets/#{style}")
      end
    end
    
    # The same as widget_stylesheet_link, but for javascripts
    def widget_javascript_link(widget, script)
      if(Widgeon::Widget.asset_mode == :widget)
        link = '<script type="text/javascript" src="'
        link << '/widgeon/' << widget.widget_name
        link << '/javascripts/' << script << '.js"></script>'
        link << "\n"
        link
      else
        javascript_include_tag(widget.web_path_to_public + "/javascripts/#{script}")
      end
    end
    
    # This is a helper used for the <tt>widget_style_links</tt> and 
    # <tt>widget_javascript_links</tt>. It takes the same options as those,
    # and calls the given block for each widget. The block will be passed an
    # object of the widget's class.
    # 
    # This will expect that the called block returns a string, and will append
    # all return strings into on.
    #
    # The result of this call will be cached in Rails fragment cache, using
    # the given cache key
    def loop_for_widgets(cache_key, *widgets, &block)
      # Check the cache. read_fragment should return nil if caching is
      # not active, so there's no need for an additional check
      cached = controller.read_fragment(cache_key)
      return cached if(cached)
      
      # If all is given, load all the widget names
      if(widgets.delete(:all))
        widgets += Widgeon::Widget.list_widgets
      end
      # If auto is given, add the automatic
      if(widgets.delete(:auto) || widgets.size == 0)
        widgets += @auto_widgets if(@auto_widgets)
      end
      # Remove duplicates
      widgets.uniq!
      loop_result = collect_strings_from(widgets) { |widget| block.call(Widgeon::Widget.load_widget(widget)) }
      
      # Write to the cache
      controller.write_fragment(cache_key, loop_result)
      loop_result
    end
    
    # Little helper to run a block on with each element of the collection,
    # and return the result as a string
    def collect_strings_from(collection, &block)
      collected_string = ''
      collection.each { |e| collected_string << block.call(e) }
      collected_string
    end
    
  end
end
