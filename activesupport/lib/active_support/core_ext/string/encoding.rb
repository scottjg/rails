module ActiveSupport #:nodoc:
  module CoreExtensions #:nodoc:
    module String
      module Encoding
        if defined?(Encoding) && "".respond_to?(:encode)
          def encoding_aware?
            true
          end
        else
          def encoding_aware?
            false
          end
        end
      end
    end
  end
end
