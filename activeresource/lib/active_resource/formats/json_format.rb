require 'active_support/json'

module ActiveResource
  module Formats
    module JsonFormat
      extend self

      def extension
        "json"
      end

      def mime_type
        "application/json"
      end

      def encode(hash, options = nil)
        ActiveSupport::JSON.encode(hash, options)
      end

      def decode(json)
        ActiveSupport::JSON.decode(json)
      end

      # Grabs errors from a json response.
      def decode_errors(json)
        Array.wrap(ActiveSupport::JSON.decode(json)['errors']) rescue []
      end

    end
  end
end
