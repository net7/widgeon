# Local dir to loadpath
$: << File.dirname(File.expand_path(__FILE__))

# Require stuff
require 'widgeon/helpers'
require 'widgeon/widgeon_class_methods'
require 'widgeon/widgeon'
require 'widgeon/widgeon_encoding'

# Install the helpers
module ActionView # :nodoc:
  module Helpers # :nodoc:
    module Widgets # :nodoc:
      include Widgeon::Helpers
    end
  end
end

# Load the pagination stuff if will_paginate is loaded
if(defined?(WillPaginate))
  require 'widgeon/widget_will_paginate'
  
  module ActionView::Helpers::Widgets
    include WidgetWillPaginate::Helpers
  end
end

ActionView::Base.class_eval do
  include ActionView::Helpers::Widgets
end