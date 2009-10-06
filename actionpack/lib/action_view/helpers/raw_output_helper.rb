module ActionView #:nodoc:
  module Helpers #:nodoc:
    module RawOutputHelper
      def raw(string)
        string.html_safe!
      end
    end
  end
end