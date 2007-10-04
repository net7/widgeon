# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar')%>
    def widget(widget_name, options = {})
      raise ArgumentError unless Widget.widget_defined?(widget_name)
      options.update(:controller => controller, :request => request)
      instance_eval <<-END
        @#{widget_name}_widget = #{widget_name.to_s.camelize}Widget.new(options)
        @#{widget_name}_widget.before_render if @#{widget_name}_widget.respond_to?(:before_render)
      END
      render :partial => "widgets/#{widget_name}/#{widget_name}_widget"
    end
  end
  
  class Widget
    attr_accessor :request, :controller
    class << self
      # Load the widgets from their folder.
      def load_widgets
        raise ArgumentError if widgets_folder.nil?
        Dir["#{widgets_folder}/**/*"].each do |widget|
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
        @widgets_folder ||= 'widgets'
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
        file_name.gsub(widgets_folder, '').gsub(/_widget[\.\w]+$/, '').gsub(/^\/+/, '')
      end
    end
    
    # Instantiate a new object, putting the <tt>request</tt> and the
    # <tt>controller</tt> objects into the widget.
    def initialize(options = {})
      options.each do |att, value|
        instance_eval <<-END
          def #{att}; @#{att} end
          def #{att}=(value); @#{att} = value end
        END
        self.send("#{att}=", value) #set
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