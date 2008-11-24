module Rails
  module PluginManager
    class Plugin
      attr_reader :uri

      def initialize(options = {})
        @name, @uri = options.delete(:name), options.delete(:uri)
        if @name.nil? && @uri.nil?
          raise ArgumentError, "A plugin needs at least a name or an URI."
        end
      end

      def name
        @name ||= extract_name
      end

      def path
        "vendor/plugins/#{name}"
      end

      protected

        def extract_name
          File.basename(uri)
        end
    end
  end
end
