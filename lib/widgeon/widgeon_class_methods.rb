module Widgeon
  class Widget
    class << self
      
      # The path under which the widgets are located
      def path_to_widgets
        @@path_to_widgets ||= 'app/views/widgets'
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
      def load_widget(widget_name)
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
      
      # Return the path to the template that will be rendered.
      # Convention: HelloWorldWidget => widgets/hello_world/hello_world_widget.html.erb
      #
      # If you do not give a template name, this will return the default template
      def path_to_template(template_name = nil)
        template_name ||= "#{widget_name}_widget"
        File.join("widgets", widget_name, template_name)
      end
      
      # Gives the filesystem path for a "static" file
      def path_to_static(name)
        # Expand the path relative to the (virtual) root. This should kill paths
        # that want to go outside the parent.
        name = File.expand_path(name, '/')
        # Now join the path to the widget's public root
        File.join(path_to_self, "public", name)
      end
      
      # Return the path to the configuration.
      # Convention: HelloWorldWidget => widgets/hello_world/hello_world.yml
      def path_to_configuration
        @path_to_configuration ||= File.join(path_to_self, "#{widget_name}.yml")
      end
      
      # Return the path to the widget's helper module file
      # Convention HelloWorldWidget => widgets/hellp_world/hello_world_helper.rb
      def path_to_helpers
        @path_to_helpers ||= File.join(path_to_self, "#{widget_name}_helper.rb")
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
      
      # Returns the url 
      
      # Returns header links that were defined for the widget, rendering it
      # for the given view.
      def widget_headers(view)
        headers = ""
        for style in @stylesheets
          headers << '<link href="' << path_to_static(style[:sheet]) << '" '
          headers << 'media="' << style[:media] << '" '
          headers << 'rel="stylesheet" '
          headers << 'type="text/css" '
          headers << "/>\n"
        end
        for js in @javascripts
          
        end
      end
      
      
      private
      
      # Private method to add a "remote call" to the widget in subclasses
      def remote_call(name, &block)
        # Just create the method. We use a "remotecall" suffix, so that the
        # caller can make sure that a call goes to a remote call method (and
        # nothing else)
        define_method("#{name}_remotecall", block)
      end
    end
  end
end