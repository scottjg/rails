module Rails
  module PluginManager
    class Plugin
      attr_reader :uri

      def initialize(options = {})
        @name, @uri = options[:name], options[:uri]
        if @name.nil? && @uri.nil?
          raise ArgumentError, "A plugin needs at least a name or an URI."
        end
      end

      def name
        @name ||= extract_name
      end

      protected

        def extract_name
          File.basename(uri)
        end
    end
  end
end
