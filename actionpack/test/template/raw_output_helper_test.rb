require 'abstract_unit'
require 'testing_sandbox'

class RawOutputHelperTest < ActionView::TestCase
  tests ActionView::Helpers::RawOutputHelper
  include TestingSandbox

  def setup
    @string = "hello"
  end

  test "raw returns the safe string" do
    result = raw(@string)
    assert_equal @string, result
    assert result.html_safe?
  end
end