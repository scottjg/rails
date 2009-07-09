require 'abstract_unit'

class OutputEscapingTest < ActiveSupport::TestCase

  test "escapeHTML shouldn't die when passed nil" do
    assert_nil CGI.escapeHTML(nil)
  end

  test "escapeHTML should escape strings" do
    assert_equal "&lt;&gt;&quot;", CGI.escapeHTML("<>\"")
  end
end
