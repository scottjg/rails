module ActiveSupport
  module Hwia
    class Nobu < Hash
      def initialize(*)
        super.customize
      end

      def symbolize_keys! #:nodoc:
        self
      end

      def stringify_keys! #:nodoc:
        self
      end

      def to_options! #:nodoc:
        self
      end

      protected
        def key_filter(key)
          key.to_s
        end
    end
  end
end
