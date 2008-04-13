# This includes the will_paginate functionality for widgets. If you want to use
# this, you *must* force the widget load ordering to load the will_paginate
# plugin before the widgeon plugin!
#
# The widget pagination can be called inside the widget using the 
# #widget_will_paginate method.
module WidgetWillPaginate
  
  # Create a hacked version of the "Renderer" of will_paginate to work with
  # widget backlinks
  class WidgetBacklinkRenderer < WillPaginate::LinkRenderer
    
    def page_link_or_span(page, span_class = 'current', text = nil)
      text ||= page.to_s
      if page and page != current_page
        @template.w.remote_link(text, backlink_options(page).merge(@options[:backlink_options])) + "\n"
      else
        @template.content_tag :span, text, :class => span_class
      end
    end
    
    private 
    
    def backlink_options(page)
      { :refresh => :default, param_name => page }
    end
  end # end class
  
  # Module for the actual helper methods
  module Helpers
    
    # This is a modified version of the original will_paginate method that can
    # be used inside a widget. This will paginate the given collection und
    # create a widget backlink instead of the normal page links.
    # 
    # By default, the widget backlink will contain the "normal" pagination 
    # options (most importantly "page"). 
    # 
    # If the widget that is called back needs additional options, these can
    # be passed using the backlink_options hash.
    #  
    # The options hash is equivalent to the one used in the standard pagination
    # helper.
    def widget_will_paginate(collection, backlink_options = {}, options = {})
      options, collection = collection, nil if collection.is_a? Hash
      unless collection or !controller
        collection_name = "@#{controller.controller_name}"
        collection = instance_variable_get(collection_name)
        raise ArgumentError, "The #{collection_name} variable appears to be empty. Did you " +
          "forget to specify the collection object for will_paginate?" unless collection
      end
      
      options[:backlink_options] = backlink_options
      
      # early exit if there is nothing to render
      return nil unless collection.page_count > 1
      options = options.symbolize_keys.reverse_merge WillPaginate::ViewHelpers.pagination_options
      # create the renderer instance
      renderer = WidgetWillPaginate::WidgetBacklinkRenderer.new collection, options, self
      # render HTML for pagination
      renderer.to_html
    end
    
  end
  
end
