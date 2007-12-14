# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar')%>
    def widget(widget_name, options = {})
      Widget.http_attributes.each { |att| options.update( att => self.send(att) ) }

      # Widget is made a class variable, so that it is automtically available
      # to the helper.
      @widget = Widget.create_widget(widget_name, options)
      @widget.before_render_call

      # Add the javascript code to the page and render the widget into a div.
      "#{@widget.send(:initialize_javascripts)}" +
      "<div id=\"#{@widget.send(:identification_key)}\">" +
      render(:partial => "widgets/#{widget_name}/#{widget_name}_widget", :locals => {  widget_name.to_sym => @widget })+
      "</div>"
    end
    
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      options[:partial] = File.join(@widget.path_to_self, partial)
      options[:locals] = { :widget => @widget }
      render(options)
    end
  end
  
  class Widget
    attr_accessor :request, :controller
    class << self
      # Regexp for extracting the widget name for a file
      # Explanation: At the end of the string, match the thing that looks like
      # <characters without dir separator>_widget.<characters><- end of string
      # The first result group will contain the widget name
      @@widget_name_re = Regexp.new('([^\\/\\\\]+)_widget\..*$')
      
      # Attempts to load the widget with the given name. The behaviour depends
      # on Rails::Configuration.cache_classes: If that is set to false, the
      # file will always be reloaded. If true, the widget class will be
      # loaded only once.
      def load_widget(widget_name)
        # Dendencies.mechanis is :load or :require, respectively
        unless(Dependencies.mechanism == :require && widget_defined?(widget_name))
          raise(ArgumentError, "No widget folder set") if widgets_folder.nil?
          load "#{widgets_folder}/#{widget_name}/#{widget_name}_widget.rb"
          "#{widget_name}_widget".classify.constantize.load_configuration
          loaded_widgets << widget_name.to_sym
        end
        raise(ArgumentError, "Unable to load widget: #{widget_name}") unless(widget_defined?(widget_name))
      end
      
      # Creates a widget from the given widget name
      def create_widget(widget_name, options = {})
        load_widget(widget_name)
        
        # Get the class of the widget and check, just to be sure
        klass = Kernel.const_get("#{widget_name.to_s.camelize}Widget")
        raise(RuntimeError, "Widget class does not exist") unless(klass.is_a?(Class))
        
        # Create the new widget
        klass.new(options)
      end
      
      # Check if a widget is defined
      def widget_defined?(widget_name)
        loaded_widgets.include?(widget_name.to_sym)
      end
      
      def loaded_widgets # :nodoc:
        @loaded_widgets ||= Set.new
      end
      
      # Load the configuration file and cache it.
      #
      # If a <b>YAML</b> file is present into the widget folder, it will be
      # loaded, and each key will be available as widget instance variable.
      #
      # <b>Convention:</b> the file should have the same name of the widget.
      #
      # Example:
      #
      #   HelloWorldWidget => hello_world.yml
      def load_configuration
        path_to_configuration = File.join(Widget.widgets_folder, widget_name, widget_name+'.yml')
        return unless File.exists?(path_to_configuration)
        YAML::load_file(path_to_configuration).to_hash.each do |att, value|
          default_attributes << att.to_sym
          attr_accessor_with_default att.to_sym, value
        end
      end
      
      # Set the widgets folder.
      #
      # Example:
      #
      #   Widgeon::Widget.widgets_folder = 'path/to/widgets'
      def widgets_folder=(folder)
        @widgets_folder = folder
      end
      
      def widgets_folder #:nodoc:
        @widgets_folder ||= File.join('app', 'views', 'widgets')
      end
      
      def widget_name_regexp
        @@widget_name_re
      end
      
      # Those attributes are always available into the widget as variables.
      def default_attributes
        @@default_attributes ||= []
      end
      
      # Those attributes are catched from the widget helper and instantiated.
      def http_attributes
        @@http_attributes ||= [ :request, :controller ]
      end
      
      # Those attributes are the cached into the class itself.
      def cached_attributes
        default_attributes + http_attributes
      end
      
      # This method return the widget name.
      #
      # Example:
      #
      #   HelloWorldWidget.name # => 'hello_world'
      def widget_name
        self.name.demodulize.underscore.gsub(/_widget/, '')
      end
    end
    
    # END OF CLASS METHODS
    
    # Instantiate a new object, create a <b>permanent state</b> into the 
    # <tt>session</tt> and put the <tt>request</tt> and the
    # <tt>controller</tt> objects into the widget.
    #
    # If the param <tt>:identifier</tt> was passed, it will be used as part of
    # the <b>page state</b> and <b>permanent state</b> identifier.
    def initialize(options = {})
      options.each { |att, value| create_instance_accessor(att, value) }
      create_instance_accessors_from_state
      create_permanent_state if permanent_state.nil?
    end
    
    # This is called by the helper before the widget is rendered. It will
    # automatically create a new <b>on page state</b> and call the 
    # <tt>before_render</tt> method.
    def before_render_call   
      before_render
      create_accessors
      create_page_state
    end
    
    def before_render #:nodoc:
    end
    
    # Return the <b>page state</b>.
    def page_state
      widget_state
    end
    
    # Return the <b>permanent state</b>.
    def permanent_state
      widget_state(true)
    end
    
    # Clean the <b>permanent state</b>.
    def clean_permanent_state
      create_permanent_state
    end
    
    # Returns the path for the widget.
    def path_to_self
      File.join(self.class.widgets_folder, self.class.widget_name.to_s)
    end
    
    protected
    # Create accessors for all instance variables that don't have one alredady
    def create_accessors
     instance_variables.each do |var|
        var.sub!('@', '') # Remmove the @ char from the variable name
        create_instance_accessor(var)
      end
    end
    
    # Makes an accessor on the current objects singleton class object 
    # (which is an accessor that only exists for the current object.
    # 
    # This does nothing if the current object already responds to the given
    # name.
    # 
    # If a value is given, the accessor is set to that. Otherwise, the value
    # is left unchanged. If a default is given, it will be set even if
    # the accessor already exists
    def create_instance_accessor(name, value = nil)
      unless(respond_to?(name))
        (class << self; self; end).class_eval do
          attr_accessor name.to_sym
        end
      end
      self.send("#{name}=", value) if(value) #set
    end
    
    # Create a new <b>page</b> state.
    def create_page_state
      create_state
    end
    
    # Create a new <b>permanent</b> state.
    def create_permanent_state
      create_state(true)
    end
    
    def create_state(permanent = false) #:nodoc:
      key = session_key(permanent)
      request.session[key] = {}

      # add instance variables to the page state
      unless permanent
        request.session[key][:attributes] = {}
        instance_variables.each do |var|
          var = var.gsub(/@/, '').to_sym
          next if self.class.cached_attributes.include?(var)
          request.session[key][:attributes][var] = self.send(var)
        end
      end
      # Make sure :attributes is stored as json, cause Marshal doesn't support
      # serializations of bindings, procedure or method objects, instances of
      # class IO, or singleton objects.
      request.session[key][:attributes] = request.session[key][:attributes].to_json
    end
    
    def widget_state(permanent = false) #:nodoc:
      request.session[session_key(permanent)]
    end
    
    def create_instance_accessors_from_state #:nodoc:
      return if page_state.nil? or page_state[:attributes].nil?
      page_state[:attributes] = case page_state[:attributes]
        when String: ActiveSupport::JSON.decode(page_state[:attributes])
        else         page_state[:attributes]
      end
      page_state[:attributes].each { |k,v| create_instance_accessor(k,v) }
    end
    
    def initialize_javascripts
      # TODO eliminate this duplicated code.
      id = self.respond_to?(:identifier) ? identifier : 'default'
      "<script type=\"text/javascript\" charset=\"utf-8\">"+
        "widget = new Widget('#{id}', '#{self.class.widget_name}');"+
      "</script>"
    end
    
    # Return an identification key useful for the template rendering or the
    # session identification.
    #
    # If <tt>:identifier</tt> is defined, will be used into the key
    # else it will be used <tt>:default</tt>.
    #
    # Example:
    #
    #   @hello_world = HelloWorldWidget.new
    #   @hello_world.send(:session_key)
    #     => :widget_hello_world_default
    #
    #   @hello_world = HelloWorldWidget.new(:identifier => 'id')
    #   @hello_world.send(:session_key)
    #     => :widget_hello_world_id
    def identification_key
      id = self.respond_to?(:identifier) ? identifier : 'default'
      "widget_#{self.class.widget_name}_#{id}".to_sym
    end
    
    # Return the session key for the state, using <tt>identification_key</tt>.
    #
    # If <tt>permanent</tt> is <tt>true</tt> the key will be generated for the
    # <b>permanent</b> state, else for the <b>page</b> one.
    #
    # Example:
    #
    #   @hello_world = HelloWorldWidget.new
    #   @hello_world.send(:session_key)
    #     => :widget_hello_world_default_page
    #
    #   @hello_world = HelloWorldWidget.new(:identifier => 'id')
    #   @hello_world.send(:session_key)
    #     => :widget_hello_world_id_page
    #
    #   @hello_world = HelloWorldWidget.new
    #   @hello_world.send(:session_key, true)
    #     => :widget_hello_world_default_permanent
    #
    #   @hello_world = HelloWorldWidget.new(:identifier => 'id')
    #   @hello_world.send(:session_key, true)
    #     => :widget_hello_world_id_permanent
    def session_key(permanent = false)
      context = permanent ? 'permanent' : 'page'
      "#{identification_key}_#{context}".to_sym
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