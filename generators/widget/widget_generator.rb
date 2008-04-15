class WidgetGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    @widget_file_name = "#{runtime_args.first.underscore}_widget.rb"
    @widget_view_file = "_#{runtime_args.first.underscore}_widget.html.erb"
    super
  end
  
  def manifest
    record do |m|
      # Check for class collisions
      m.class_collisions class_name
      
      m.directory File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'code')
      m.directory File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'views')
      m.directory File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'public')
      m.directory File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'public', 'javascripts')
      m.directory File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'public', 'stylesheets')
      
      # Create files
      m.template 'widget.rb', File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'code', @widget_file_name),
        :assigns => { :widget_class_name => class_name }
      m.template 'widget.rhtml', File.join(Widgeon::WIDGEON_REL_ROOT, name.underscore, 'views', @widget_view_file),
        :assigns => { :widget_name => name.underscore }
    end
  end
end