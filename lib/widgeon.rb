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
    
    # TODO merge with #widget
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      options[:partial] = "widgets/#{@widget.class.widget_name}/#{partial}"
      options[:locals] = { :widget => @widget }
      render(options)
    end
    
    private
    def render_widget
      @widget.render
      "<div id=\"#{@widget.id}\">#{render :partial => @widget.class.path_to_helper, :locals => { (@widget.class.widget_name+"_widget").to_sym => @widget }}</div>"
    end
  end

  class Widget
    class << self
      def path_to_widgets
        @@path_to_widgets ||= 'app/views/widgets'
      end
      
      def callbacks
        @@callbacks ||= [ :before_render ]
      end
      
      def loaded_widgets
        @@loaded_widgets ||= {}
      end
      
      # Attempts to load the widget with the given name.
      # The behaviour depends on:
      #   config.cache_classes = true or false
      #
      # It'd defined in <tt>environment.rb</tt> or in the specific environment
      # configuration file.
      #
      # If that is set to false, the file will always be reloaded.
      # If true, the widget class will be loaded only once.
      def load(widget_name)
        raise(ArgumentError, "Unable to load widget: " + widget_name) unless exists?(widget_name)
        return loaded_widgets[widget_name] if !loaded_widgets[widget_name].nil? && Dependencies.mechanism == :require
        require_or_load File.join(path_to_widgets, widget_name, widget_name+'_widget')
        klass = (widget_name+"Widget").classify.constantize
        klass.load_configuration
        loaded_widgets[widget_name] = klass
        klass
      end
      
      # Check if a widget exists in the path defined in path_to_widgets.
      def exists?(widget_name)
        File.exists?(path_to_widgets+'/'+widget_name.to_s)
      end
      
      # Load the configuration file.
      def load_configuration
        return unless File.exists? path_to_configuration
        YAML::load_file(path_to_configuration).to_hash.each do |att, value|
          attr_accessor_with_default att.to_sym, value
        end
      end
      
      # Return the root of the current widget.
      # Convention: HelloWorldWidget => app/views/widgets/hello_world
      def path_to_self
        @path_to_self ||= File.join(path_to_widgets, widget_name)
      end
      
      # Return the path to the helper that will be rendered.
      # Convention: HelloWorldWidget => widgets/hello_world/hello_world_widget.html.erb
      def path_to_helper
        @path_to_helper ||= File.join("widgets", widget_name, "#{widget_name}_widget.html.erb")
      end
      
      # Return the path to the configuration.
      # Convention: HelloWorldWidget => widgets/hello_world/hello_world.yml
      def path_to_configuration
        @path_to_configuration ||= File.join(path_to_self, "#{widget_name}.yml")
      end
      
      # Return the widget name, based on the class name.
      #
      # Example:
      #   ShinySidebarWidget #=> shiny_sidebar
      def widget_name
        @widget_name ||= self.name.underscore.gsub(/_widget/, '')
      end
    end
    
    # Create a new instance of the widget.
    # Each value passed in <tt>options</tt> will be available as attribute.
    def initialize(options = {})
      options.each { |k,v| create_instance_accessor k, v }
    end
            
    # Return the id, if explicitly specified, or the widget_name.
    def id
      @id ||= self.class.widget_name
    end
        
    def render #:nodoc:
      call_callbacks_chain
      create_instance_accessors_from_attributes
    end
    
    def before_render #:nodoc:
    end
    
    private
    def create_instance_accessor(name, value = nil) #:nodoc:
      (class << self; self; end).class_eval { attr_accessor name }
      self.send("#{name}=", value)
    end
    
    # Create attribute accessors, starting from instance attributes.
    def create_instance_accessors_from_attributes
      self.instance_variables.each do |attribute|
        attribute = attribute.gsub('@', '')
        next if self.respond_to? attribute.to_sym
        create_instance_accessor attribute, instance_variable_get("@#{attribute}".to_sym)
      end
    end
    
    # Call all the callbacks.
    def call_callbacks_chain
      self.class.callbacks.each { |method| self.send method }
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