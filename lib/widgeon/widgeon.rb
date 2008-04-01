# Widgeon
module Widgeon

  # The base class for all widgets. This encapsulates the basic behaviour of the
  # widget objects.
  class Widget
    
    # Create a new instance of the widget.
    # Each value passed in <tt>options</tt> will be available as attribute.
    def initialize(controller, request, options = {})
      raise(ArgumentError, "Controller invalid") unless(controller.is_a?(ActionController::Base))
      raise(ArgumentError, "Request invalid (#{request.class})") unless(request.is_a?(ActionController::AbstractRequest))
      load_helpers! # Load the helpers
      @id = options.delete(:id) # We must set that manually because we can't overwrite the accessor method
      create_instance_accessor(:controller, controller);
      create_instance_accessor(:request, request)
      create_instance_accessor(:call_options, options)
      load_configuration! # Load the configuration options first
      # Now activate the passed options, overwritig config file options
      # if neccessary
      options.each { |option, value| create_instance_accessor option, value } 
      # Now check for static callback options. These can overwrite options
      # from the paramter if necessary
      check_for_static_callback!
    end
            
    # Return the id. The default id is "default"
    def id
      @id ||= "default"
    end
    
    # Returns the "global id". This is a combination of the widget's id
    # and the widget's class.
    def global_id
      @global_id ||= "#{self.class.widget_name}-#{id}"
    end
        
    def render #:nodoc:
      call_callbacks_chain
      create_instance_accessors_from_attributes
    end
    
    def before_render #:nodoc:
    end
    
    private
    
    # Setup the widget for "static" callback operation (checks if the current
    # page has been loaded with paramters that indicate that this widget 
    # instance has been loaded in "callback" mode.
    def check_for_static_callback!
      is_callback = (@request.parameters && @request.parameters[:widgeon_callback])
      @callback_active = true if(is_callback)
      # First check if some callback parameter exists at all
      return unless(is_callback)
      # The widgeon_class/widgeon_id parameters allow for a quick check if the
      # callback is for this widget instance (without decoding the options)
      return unless(@request.parameters[:widgeon_class] == self.class.widget_name)
      return unless(@request.parameters[:widgeon_id] == id)
      
      # Set the callback flag
      @callback_active = true
      
      callback_options = WidgeonEncoding.decode_options(@request.parameters[:widgeon_callback])
      # For security, check the callback options agains the parameters
      raise(ArgumentError, "Callback parameters did not match") unless(callback_options[:widget_id] == id && callback_options[:widget_class] == self.class.widget_name)
      setup_static_callback!(callback_options)
    end
    
    # Setup the widget for static callback wth the given options
    def setup_static_callback!(options)
      # Remove the options for the widgeon framework
      options.delete(:widget_class)
      options.delete(:widget_id)
      # Now setup the options
      options.each do |cb_option, value|
        create_instance_accessor(cb_option, value)
      end
    end
    
    # Indicates if this widget is in a callback operation. This will return
    # if the current page (or widget) is loaded as part of a widget callback
    # operation - *even if* the current widget is *not* the target of the 
    # callback. (In other words: This will also be true if we are currently
    # performing a callback for another widget)
    def is_callback?
      @callback_active
    end
    
    # Get the widget's session store, which is a hash stored in the current
    # session. The contents will be private for the widget class/id combination
    # of this widget
    def widget_session
      @request.session["#{self.class.widget_name}-#{id}"] ||= {}
    end
    
    # Create an instance variable and an accessor for it with the given name and
    # value. This will raise an error if the name is already defined.
    def create_instance_accessor(name, value = nil) #:nodoc:
      name = name.to_sym
      # Check if something is already defined
      if(respond_to?(name) || respond_to?("#{name}="))
        # We will bail out, unless this is an instance variable that was
        # previously defined using create_instance_accessor
        unless(instance_variables.include?("@#{name}") && created_instance_vars.include?(name))
          raise(ArgumentError, "An option tried to overwrite #{name}")
        end
      else
        # If nothing exists, we can define the accessor
        (class << self; self; end).class_eval { attr_accessor name }
        created_instance_vars << name
      end
      
      # Assign the value to the accessor
      self.send("#{name}=", value)
    end
    
    # Stores the variables that were created by create_instance_accessor.
    # Only these may be overwritten by that method.
    def created_instance_vars
      @created_instance_vars ||= []
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
    def load_configuration!
      return unless File.exists? self.class.path_to_configuration
      unless(@config_hash && Dependencies.mechanism != :require)
        @config_hash = YAML::load_file(self.class.path_to_configuration).to_hash
      end
      @config_hash.each do |att, value|
        create_instance_accessor(att.to_sym, value)
      end
    end
    
    # Loads the helpers for the wdgets if they exist. Currently,
    # helpers for a widget will automatically be available in 
    # *all* views.
    def load_helpers!
      return unless File.exists?(helper_file = self.class.path_to_helpers)
      require_or_load helper_file
      # TODO: These calls can be avoided when using "require"
      mod = "#{self.class.widget_name.classify}Helper".constantize
      raise(RuntimeError, "Didn't find correct helper module for #{self.class}") unless(mod.is_a?(Module))
      ActionView::Base.class_eval do
        include mod
      end
    end
  end
end