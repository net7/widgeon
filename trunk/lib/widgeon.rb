# Widgeon
module Widgeon
  module Helpers
    # Instantiate and render a widget.
    #
    # Example:
    #
    #   <%= widget(:sidebar, :title => 'My Shiny Sidebar')%>
    def widget(widget_name, options = {})
    end
  end
  
  class Widget
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
        @widgets_folder ||= File.join(RAILS_ROOT, 'widgets')
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
    
    def initialize(options = {}) # :nodoc:
      options.each {|var_name, value| self.instance_variable_set("@#{var_name}".to_sym, value) }
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