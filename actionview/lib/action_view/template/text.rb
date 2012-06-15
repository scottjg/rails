module ActionView #:nodoc:
  # = Action View Text Template
  class Template
    class Text < String #:nodoc:
      attr_accessor :type

      def initialize(string, type = nil)
        super(string.to_s)
        @type = type || :text
      end

      def identifier
        'text template'
      end

      def inspect
        'text template'
      end

      def render(*args)
        to_s
      end

      def formats
        [@type.to_sym]
      end
    end
  end
end
