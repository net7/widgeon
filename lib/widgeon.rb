# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar')%>
    def widget(widget_name, options = {})
      load(widget_name.to_s)
    end
  end

  class Widget
    class << self
      def path_to_widgets
        @@path_to_widgets ||= 'app/views/widgets'
      end
      
      # Attempts to load the widget with the given name. The behaviour depends
      # on Rails::Configuration.cache_classes: If that is set to false, the
      # file will always be reloaded. If true, the widget class will be
      # loaded only once.
      def load(widget_name)
        raise(ArgumentError, "Unable to load widget: " + widget_name) unless exists?(widget_name)
        require_or_load File.join(path_to_widgets, widget_name, widget_name+'_widget')
      end
      
      # Check if a widget exists in the path defined in path_to_widgets.
      def exists?(widget_name)
        File.exists?(path_to_widgets+'/'+widget_name.to_s)
      end
    end
    
    # Create a new instance of the widget.
    # Each value passed in <tt>options</tt> will be available as attribute.
    def initialize(options = {})
      options.symbolize_keys.each { |k,v| self.class.class_eval { attr_accessor_with_default k, v } }
    end
  end
end