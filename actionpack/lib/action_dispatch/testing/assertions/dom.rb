require 'loofah'

module ActionDispatch
  module Assertions
    module DomAssertions
      # \Test two HTML strings for equivalency (e.g., identical up to reordering of attributes)
      #
      #   # assert that the referenced method generates the appropriate HTML string
      #   assert_dom_equal '<a href="http://www.example.com">Apples</a>', link_to("Apples", "http://www.example.com")
      def assert_dom_equal(expected, actual, message = "")
        expected_dom = Loofah.fragment(expected)
        actual_dom   = Loofah.fragment(actual)

        equivalent = true
        expected_dom.children.each_with_index do |child, i|
          expected = child.attribute_nodes.sort_by { |a| a.name }
          actual = actual_dom.children[i].attribute_nodes.sort_by { |a| a.name

          expected.each_with_index do |attr, idx|
            equivalent &&= attr.name == actual[idx].name  &&
                            attr.value == actual[idx].value
          end
        end
        assert equivalent
      end

      # The negated form of +assert_dom_equivalent+.
      #
      #   # assert that the referenced method does not generate the specified HTML string
      #   assert_dom_not_equal '<a href="http://www.example.com">Apples</a>', link_to("Oranges", "http://www.example.com")
      def assert_dom_not_equal(expected, actual, message = "")
        expected_dom = Loofah.fragment(expected).to_s
        actual_dom   = Loofah.fragment(actual).to_s
        assert_not_equal expected_dom, actual_dom
      end
    end
  end
end
