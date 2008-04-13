require 'ftools'

module Widgeon
  
  # Root path to root directory where the widgets are located. 
  WIDGEON_ROOT = File.join(RAILS_ROOT, 'app', 'views', 'widgets')
  
  # Path to the public asset directory for the widgets (inside Rails' public dir)
  WIDGEON_PUBLIC_ASSETS = File.join(RAILS_ROOT, 'public', 'widgets')
  
  class Widget
    class << self
      
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
      
      # Set the inline_styles property
      def inline_styles=(value)
        @@inline_styles = value
      end
      
      # Indicates the method used for assets (javascripts and stylesheets). 
      # If set to <tt>:widget</tt> the assets will be served directly from the
      # widget's directory. 
      #
      # If set to <tt>:install</tt> the assets will be copied to the public
      # asset directory. 
      #
      # While the <tt>:widget</tt> setting is more comfortable for development,
      # the <tt>:install</tt> will cause the assets to be served as static 
      # content and allows Rails' optimizations to be used - this is the
      # recommended setting for production.
      #
      # The default mode is <tt>:widget</tt>
      def asset_mode
        @@asset_mode ||= :widget
      end
      
      # Sets the asset_mode. This will *also* install the assets to the Rails
      # asset directory if set to :install
      def asset_mode=(value)
        raise(ArgumentError, "Illegal value #{value}") unless([:install, :widget].include?(value))
        reinstall = ((value == :install) && (asset_mode != :install))
        @@asset_mode = value
        install_assets if(reinstall)
      end
      
      
      # Gets a list of the widget's 
      
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
        widget_name = widget_name.to_sym
        raise(ArgumentError, "Unable to load widget from #{WIDGEON_ROOT}: " + widget_name.to_s) unless exists?(widget_name)
        return loaded_widgets[widget_name] if !loaded_widgets[widget_name].nil? && Dependencies.mechanism == :require
        require_or_load File.join(path_to_code(widget_name))
        klass = ("#{widget_name}Widget").classify.constantize
        loaded_widgets[widget_name] = klass
        klass
      end
      
      # Returns a list with the names of all widgets found on the system
      def list_widgets
        @@widget_list ||= begin
          list = []
          Dir.foreach(WIDGEON_ROOT) do |file|
            name = File.basename(file)
            if(exists?(name))
              list << name
            end
          end
          list
        end
      end
      
      # Check if a widget exists in the path defined in path_to_widgets.
      def exists?(widget_name)
        File.exists?("#{path_to_code(widget_name)}.rb")
      end
      
      # Return the widget name, based on the class name.
      #
      # Example:
      #   ShinySidebarWidget #=> shiny_sidebar
      def widget_name
        @widget_name ||= self.name.underscore.gsub(/_widget/, '')
      end
      
      # Return a list with the names of all style sheets configured for this
      # widget
      def stylesheets
        @stylesheets ||= begin
          if(@style_config && !@style_config.include?(:all))
            @style_config.collect { |style| File.basename(style.to_s, ".css") }
          else
            list_files(path_to_stylesheets, ".css")
          end
        end
      end
      
      # Returns 
      
      # Return a list with the names of all javscript files configured for this
      # widget
      def javascripts
        @javascripts ||= begin
          if(@js_config && !@js_config.include?(:all))
            @js_config.collect { |script| File.basename(script.to_s, ".js") }
          else
            list_files(path_to_javascripts, ".js")
          end
        end
      end
      
      # All path-related methods. See the definition of WIDGEON_ROOT above.
      
      # Return the root of the current widget.
      # Convention: HelloWorldWidget => WIDGEON_ROOT/hello_world
      def path_to_self
        @path_to_self ||= File.join(WIDGEON_ROOT, widget_name)
      end
      
      # Returns the path to the widget's code file. Doesn't include the ".rb" 
      # file extension.
      def path_to_code(widget_name)
        File.join(WIDGEON_ROOT, widget_name.to_s, 'code', "#{widget_name}_widget")
      end
      
      # Return the path where the templates for this class are located.
      # Convention: HelloWorldWidget => path_to_self/templates
      #
      # If you do not give a template name, this will return the default template
      #
      # This is a relative path that will be added to Rails' template path.
      def path_to_templates
        @path_to_templates ||=  WIDGEON_ROOT + "/#{widget_name}/views"
      end
      
      # Return the path to the widget's "asset" directory. path_to_self/public
      def path_to_assets
        @path_to_assets ||= File.join(path_to_self, 'public')
      end
      
      # Return the path to the widget's stylesheets
      def path_to_stylesheets
        @path_to_stylesheets ||= File.join(path_to_self, 'public', 'stylesheets')
      end
      
      # Return the path to the widget's stylesheets
      def path_to_javascripts
        @path_to_javascripts ||= File.join(path_to_self, 'public', 'javascripts')
      end
      
      # Returns the web path to the public (Rails-controlled) asset directory
      # for this widget. This allows to pass a widget name to be able to 
      # use this without a loaded widget class
      def web_path_to_public(name = nil)
        name ||= widget_name
        '/widgets/' << name
      end
      
      # Gives the filesystem path for a "static" file. The "name" part may
      # be a directory path; the method will always treat the directory as 
      # relative to WIDGEON_ROOT/public - it will try to block attempts to 
      # have this point to a parent path.
      def path_to_static_file(name)
        # Expand the path relative to the (virtual) root. This should kill paths
        # that want to go outside the parent.
        name = File.expand_path(name, '/')
        # Now join the path to the widget's public root
        File.join(path_to_assets, name)
      end
      
      # Return the path to the configuration.
      # Convention: HelloWorldWidget => widgets/hello_world/hello_world.yml
      def path_to_configuration
        @path_to_configuration ||= File.join(path_to_self, "#{widget_name}.yml")
      end
      
      # Returns the widget's style files concentaned into one string
      def widget_style
        return @widget_style if(@widget_style && (Dependencies.mechanism == :require))
        @widget_style = load_style_files
      end
      
      
      
      private
      
      # Loads the widget's style sheet(s) from a file
      def load_style_files
        styles = ''
        for sheet in stylesheets
          styles << File.open(File.join(path_to_stylesheets, "#{sheet}.css")) { |file| file.read } 
        end
        styles == '' ? nil : styles
      end
      
      # Installs the assets of all widgets in Rails' global asset directory.
      # Only to be called on init
      def install_assets
        for widget in list_widgets
          klass = load_widget(widget)
          klass.send(:install_assets_for_widget) # call the private method :)
        end
      end
      
      # This install the assets for the current class in Rails' asset diretories
      # This should only be called from install_assets.
      def install_assets_for_widget
        return if((asset_mode != :install) || !File.exists?(path_to_assets)) # only if we have to
        asset_path = File.join(WIDGEON_PUBLIC_ASSETS, widget_name)
        install_dir(path_to_assets, asset_path)
      end
      
      # Installs the files from path to destination, recursively stepping into
      # subdirectories
      def install_dir(path, destination)
        File.makedirs(destination)
        Dir.foreach(path) do |file|
          full = File.join(path, file)
          if(File.stat(full).directory? && !(file =~ /^\./))
            install_dir(full, File.join(destination, file))
          elsif(File.stat(full).file?)
            File.install(full, destination)
          end
        end
      end
      
      # Returns a list of all filenames with the given extension from 
      # the given directory
      def list_files(path, extension)
        files = []
        return files unless(File.exists?(path))
        Dir.foreach(path) do |file|
          if(File.extname(file) == extension)
            files << File.basename(file, extension)
          end
        end
        files
      end
      
      # Private method to add a "remote call" to the widget in subclasses
      def callback(name, &block)
        # Just create the method. We use a "remotecall" suffix, so that the
        # caller can make sure that a call goes to a remote call method (and
        # nothing else)
        define_method("#{name}_remotecall", block)
      end
     
      # Used to configure the styles in the subclass. This may use <tt>:all</tt>
      # to use all stylesheets in the style directory. This is the default
      # until explicitly configured
      def style(*args)
        @style_config ||= []
        @style_config += args
      end
      
      # Used to configure the javascript files for the subclass. See the 
      # <tt>style</tt> method.
      def script(*args)
        @js_config ||= []
        @js_config += args
      end
      
    end
  end
end
