# Widgeon
module Widgeon
  class Widget
    PATH_TO_WIDGETS = 'app/views/widgets'
    
    class << self
      def path_to_widgets
        PATH_TO_WIDGETS
      end
    end
  end
end