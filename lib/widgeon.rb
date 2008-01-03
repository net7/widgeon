# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar') %>
    def widget(widget_name, options = {})
      @widget = Widget.load(widget_name.to_s).new(options)
      render_widget
    end
    
    private
    def render_widget
      "<div id=\"#{@widget.id}\">#{render :partial => @widget.path_to_helper, :locals => { @widget.widget_name.to_sym => @widget }}</div>"
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
        (widget_name+"Widget").classify.constantize
      end
      
      # Check if a widget exists in the path defined in path_to_widgets.
      def exists?(widget_name)
        File.exists?(path_to_widgets+'/'+widget_name.to_s)
      end
    end
    
    # Create a new instance of the widget.
    # Each value passed in <tt>options</tt> will be available as attribute.
    def initialize(options = {})
      options.each { |k,v| create_instance_accessor k, v }
    end
    
    # Return the path to the helper that will be rendered.
    def path_to_helper
      @path_to_helper ||= File.join("widgets", widget_name, "#{widget_name}_widget.html.erb")
    end
    
    # Return the id, if explicitly specified, or the widget_name.
    def id
      @id ||= widget_name
    end
    
    # Return the widget name, based on the class name.
    #
    # Example:
    #   ShinySidebarWidget #=> shiny_sidebar
    def widget_name
      @widget_name ||= self.class.name.underscore.gsub(/_widget/, '')
    end
    
    private
    def create_instance_accessor(name, value = nil)
      (class << self; self; end).class_eval { attr_accessor name }
      self.send("#{name}=", value)
    end
  end
end

module ActionView # :nodoc:
  module Helpers # :nodoc:
    module Widgets # :nodoc:
      include Widgeon::Helpers
    end
  end
end

ActionView::Base.class_eval do
  include ActionView::Helpers::Widgets
end