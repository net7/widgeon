# Widgeon
module Widgeon

  # The base class for all widgets. This encapsulates the basic behaviour of the
  # widget objects.
  class Widget
    class << self
      
      # The path under which the widgets are located
      def path_to_widgets
        @@path_to_widgets ||= 'app/views/widgets'
      end
      
      def callbacks
        @@callbacks ||= [ :before_render ]
      end
      
      # Caches already loaded widget classes.
      def loaded_widgets
        @@loaded_widgets ||= {}
      end
      
      # Indicates if the widget engine should use inline css styles. These
      # can be disabled if the widget syles are moved to a "normal" stylesheet
      # for performance
      def inline_styles
        @@inline_styles = true if(!defined?(@@inline_styles)) # ||= WILL NOT WORK
        @@inline_styles 
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
        loaded_widgets[widget_name] = klass
        klass
      end
      
      # Check if a widget exists in the path defined in path_to_widgets.
      def exists?(widget_name)
        File.exists?(File.join(path_to_widgets, widget_name.to_s))
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
      
      # Reads the stylesheet file for the widget (<widget_name>.css in the
      # widget's directory and returns it's contents as a string.
      #
      # If no style exists, this returns nil
      def widget_style
        style_path = File.join(path_to_self, "#{widget_name}.css")
        if(File.exists?(style_path))
          File.open(style_path) { |file| file.read }
        else
          nil
        end
      end
      
    end
    
    # END OF CLASS METHODS
    
    # Create a new instance of the widget.
    # Each value passed in <tt>options</tt> will be available as attribute.
    def initialize(options = {})
      create_instance_accessor(:call_options, options)
      options.each { |option, value| create_instance_accessor option, value }
      load_configuration # Load the configuration file
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
    
    # Create an instance variable and an accessor for it with the given name and
    # value. This will raise an error if the name is already defined.
    def create_instance_accessor(name, value = nil) #:nodoc:
      name = name.to_sym
      raise(ArgumentError, "An option tried to overwrite #{name}") if(respond_to?(name) || respond_to?("#{name}="))
      (class << self; self; end).class_eval { attr_accessor name }
      self.send("#{name}=", value)
    end
    
    # Create attribute accessors, starting from instance attributes.
    def create_instance_accessors_from_attributes
      self.instance_variables.each do |attribute|
        attribute = attribute.gsub('@', '')
        unless((respond_to?(attribute) || respond_to?("#{attribute}=")))
          create_instance_accessor attribute, instance_variable_get("@#{attribute}".to_sym)
        end
      end
    end
    
    # Call all the callbacks.
    def call_callbacks_chain
      self.class.callbacks.each { |method| self.send method }
    end
    
    # Load the configuration file.
    def load_configuration
      return unless File.exists? self.class.path_to_configuration
      unless(@config_hash && Dependencies.mechanism != :require)
        @config_hash = YAML::load_file(self.class.path_to_configuration).to_hash
      end
      @config_hash.each do |att, value|
        create_instance_accessor(att.to_sym, value)
      end
    end
    
  end
end