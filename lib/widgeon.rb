# Local dir to loadpath
$: << File.dirname(File.expand_path(__FILE__))

# Require stuff
require 'widgeon/helpers'
require 'widgeon/widgeon'

# Install the helpers
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
