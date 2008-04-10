# Widgeon
module Widgeon

  # The base class for all widgets. This encapsulates the basic behaviour of the
  # widget objects. The widget object's life cycle is as follows:
  # 
  # 1. The widget class is loaded/retrieved
  # 2. The widget object is instanciated with the options passed.
  # 3. The configuration is loaded and all object accessors are set up
  # 4. The *on_init* method is called, if it exists. 
  # 5. Accessors are created for new variables
  class Widget
    
    # Create a new instance of the widget.
    # Each value passed in <tt>options</tt> will be available as attribute.
    def initialize(view, request, options = {})
      raise(ArgumentError, "Controller invalid") unless(view.respond_to?(:render))
      raise(ArgumentError, "Request invalid (#{request.class})") unless(request.is_a?(ActionController::AbstractRequest))
      @id = options.delete(:id) # We must set that manually because we can't overwrite the accessor method
      create_instance_accessor(:view, view)
      create_instance_accessor(:controller, view.controller);
      create_instance_accessor(:request, request)
      create_instance_accessor(:call_options, options)
      load_configuration! # Load the configuration options first
      # Now activate the passed options, overwritig config file options
      # if neccessary
      options.each { |option, value| create_instance_accessor option, value } 
      # Now check for static callback options. These can overwrite options
      # from the paramter if necessary
      check_for_static_callback!
      on_init if(self.respond_to?(:on_init))
      create_instance_accessors_from_attributes
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
 
    # Renders the widget itself, using the main widget template, enclosing it
    # in a <div> element and adding inlines styles if necessary.
    def render
      content = render_template
      "#{inline_style}<div id=\"#{global_id}\">#{content}</div>"
    end
    
    # Render a template from the current widget directory
    def render_template(template = nil, options = {})
      # Save the widget object from the view. This is necessary in case 
      # a widget calls another widget (we expect to use the "inner" widget
      # call to use the "inner" widget, but we must restore the object
      # when we return control to the "outer" call
      caller_widget = view.w
      view.current_widget = self # Set the view's current widget to this one
      # template ||= self.class.widget_name + "_widget"
      # options[:file] = File.join(RAILS_ROOT, 'app', 'views', 'widgets', self.class.widget_name, "_#{template}.html.erb")
      options[:partial] = self.class.path_to_template(template)
      options[:use_full_path] = false
      result = view.render(options)
      view.current_widget = caller_widget # Restore the original state of the view
      result
    end
    
    def on_init #:nodoc:
    end
    
    private
    
    # In case some method cannot be handled locally, it will be passed on to 
    # the view. This makes all helpers etc. available in the widget methods
    # (that can thus be written like helpers)
    def method_missing(method, *args)
      if(@view.public_methods.include?(method.to_s))
        @view.method(method).call(*args)
      else
        super(method, *args)
      end
    end
    
    # Helper that returns the "inline style" for the widget. This will return
    # a <style> tag to be included in the HTML if the widget has a stylesheet
    # *and* if the <tt>inline_styles</tt> property of the Widget engine is true
    def inline_style
      @style ||= 
      if(self.class.inline_styles && (w_style = self.class.widget_style))
        "<style type='text/css'><!--\n#{w_style}\n--></style>\n"
      else
        ""
      end
    end
    
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
    
  end
end