# Widgeon
module Widgeon
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
  end
end