# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar')%>
    def widget(widget_name, options = {})
      raise(ArgumentError, "Widget not loaded: #{widget_name}") unless Widget.widget_defined?(widget_name)
      options.update(:controller => controller, :request => request, :widget_name => widget_name)
      # Get the class of the widget and check, just to be sure
      klass = Kernel.const_get("#{widget_name.to_s.camelize}Widget")
      raise(RuntimeError, "Widget class does not exist") unless(klass.is_a?(Class))
      
      widget = klass.new(options)
      widget.before_render_call
      
      render(:partial => "widgets/#{widget_name}/#{widget_name}_widget", :locals => {  widget_name.to_sym => widget })
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
      
      # Load the widgets from their folder.
      def load_widgets
        raise(ArgumentError, "No widget folder set") if widgets_folder.nil?
        Dir["#{widgets_folder}/**/*_widget.rb"].each do |widget|
          unless loaded_widgets.include?(widget)
            require widget
            loaded_widgets << widget_name(widget).to_sym
          end
        end
      end
      
      # Check if a widget is defined
      def widget_defined?(widget_name)
        loaded_widgets.include?(widget_name)
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

      # Return the widget name starting from the file name.
      #
      # Example:
      #
      #   file_name = 'path/to/widgets/sidebar_widget.rb'
      #   Widgeon::Widget.widget_name(file_name) # => sidebar
      def widget_name(file_name)
        unless(md = @@widget_name_re.match(file_name))
          raise(ArgumentError, "Filename #{file_name} is not a legal widget file") 
        end
        md[1] # Return the first result group of the RE match
       end
    end
    
    # END OF CLASS METHODS
    
    # Instantiate a new object, putting the <tt>request</tt> and the
    # <tt>controller</tt> objects into the widget.
    def initialize(options = {})
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