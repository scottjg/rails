require 'abstract_unit'

class OutputEscapingTest < ActiveSupport::TestCase

  test "escape_html shouldn't die when passed nil" do
    assert SafeERB::Util.h(nil).blank?
  end

  test "escapeHTML should escape strings" do
    assert_equal "&lt;&gt;&quot;", SafeERB::Util.h("<>\"")
  end

  test "escapeHTML shouldn't touch explicitly safe strings" do
    # TODO this seems easier to compose and reason about, but
    # this should be verified
    assert_equal "<", SafeERB::Util.h("<".html_safe)
  end

  test "Standard library's ERB should behave like Matz intended" do
    assert_equal 'YO&', ERB.new("YO").result + "&"
  end

  test "SafeERB should behave like the Rails team intended" do
    assert_equal 'YO&amp;', SafeERB.new("YO").result + "&"
  end
end
