require 'loofah'

module ActionDispatch
  module Assertions
    module DomAssertions
      # \Test two HTML strings for equivalency (e.g., identical up to reordering of attributes)
      #
      #   # assert that the referenced method generates the appropriate HTML string
      #   assert_dom_equal '<a href="http://www.example.com">Apples</a>', link_to("Apples", "http://www.example.com")
      def assert_dom_equal(expected, actual, message = "")
        assert compare_doms_from_strings(expected, actual)
      end

      # The negated form of +assert_dom_equivalent+.
      #
      #   # assert that the referenced method does not generate the specified HTML string
      #   assert_dom_not_equal '<a href="http://www.example.com">Apples</a>', link_to("Oranges", "http://www.example.com")
      def assert_dom_not_equal(expected, actual, message = "")
        assert_not_equal compare_doms_from_strings(expected, actual)
      end

      protected
        def compare_doms_from_strings(expected, actual)
          expected_dom = Loofah.fragment(expected)
          actual_dom   = Loofah.fragment(actual)

          expected_dom.children.each_with_index do |child, i|
            return false unless attributes_are_equal?(child, actual_dom.children[i])
          end
          true
        end

        def attributes_are_equal?(element, other_element)
          expected = element.attribute_nodes.sort_by { |a| a.name }
          actual = other_element.attribute_nodes.sort_by { |a| a.name }

          expected.each_with_index do |attr, i|
            return false unless attr.name == actual[i].name && attr.value == actual[i].value
          end
          true
        end
    end
  end
end
