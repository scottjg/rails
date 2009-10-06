require 'abstract_unit'

class OutputEscapingTest < ActiveSupport::TestCase

  test "escapeHTML shouldn't die when passed nil" do
    assert_nil CGI.escapeHTML(nil)
  end

  test "escapeHTML should escape strings" do
    assert_equal "&lt;&gt;&quot;", CGI.escapeHTML("<>\"")
  end

  test "escapeHTML shouldn't touch explicitly safe strings" do
    # TODO this seems easier to compose and reason about, but
    # this should be verified
    assert_equal "<", CGI.escapeHTML("<".mark_html_safe)
  end

end
