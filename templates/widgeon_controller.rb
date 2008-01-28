class WidgeonController < ApplicationController
  def index
    if request.xhr?
      raise(ArgumentError, "Widget not found") unless Widgeon::Widget.loaded_widgets.include?(params[:widget_name].to_sym) 
      options = {:controller => @controller, :request => request}
      widget  = Widgeon::Widget.create_widget(params[:widget_name], options)
      render :text => widget.send(params[:handler].to_sym, params), :status => 200
    end
  end
  
  def stylesheet
    headers['Content-Type'] = 'application/css'
    render :file => "#{Widgeon::Widget.path_to_widgets}/#{params[:widget]}/#{params[:widget]}.css"
  end
end