# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar')%>
    def widget(widget_name, options = {})
      options.update(:controller => controller, :request => request, :widget_name => widget_name)
      
      # Widget is made a class variable, so that it is automtically available to the
      # helper
      @widget = Widget.create_widget(widget_name, options)
      @widget.before_render_call
      
      render(:partial => "widgets/#{widget_name}/#{widget_name}_widget", :locals => {  widget_name.to_sym => @widget })
    end
    
    # Helper to render a partial in the widget folder
    def widget_partial(partial, options = {})
      options[:partial] = File.join(@widget.self_folder, partial)
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
      
      # Set the widgets folder.
      #
      # Example:
      #
      #   Widgeon::Widget.widgets_folder = 'path/to/widgets'
      def widgets_folder=(folder)
        @widgets_folder = folder
      end
      
      def widgets_folder #:nodoc:
        @widgets_folder ||= 'app/views/widgets'
      end

      def views_folder #:nodoc:
        'app/views/widgets'
      end
      
    end
    
    # END OF CLASS METHODS
    
    # Instantiate a new object, putting the <tt>request</tt> and the
    # <tt>controller</tt> objects into the widget.
    def initialize(options = {})
      load_configuration
      options.each do |att, value|
        create_instance_accessor(att, value)
      end
    end
    
    # This is called by the helper before the widget is rendered. It will
    # automatically call the before_render method, if one is defined in the
    # class
    def before_render_call
      before_render if(respond_to?(:before_render))
      create_accessors
    end
    
    # returns the folder where this widget resides
    def self_folder
      File.join('widgets', widget_name.to_s)
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
    
    def load_configuration
      widget_name = self.class.name.underscore.gsub(/_widget/, '')
      path_to_configuration = File.join(Widget.widgets_folder, widget_name, widget_name+'.yml')
      return unless File.exists?(path_to_configuration)
      YAML::load_file(path_to_configuration).to_hash.each do |att, value|
        create_instance_accessor(att, value)
      end
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