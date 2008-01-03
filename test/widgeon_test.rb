require 'test/test_helper'
require 'test/unit'
require 'vendor/plugins/widgeon/test/test_helper'

class WidgeonTest < Test::Unit::TestCase
  include Widgeon

  def test_widget_paths
    assert_equal("app/views/widgets", Widget.path_to_widgets)
  end
end