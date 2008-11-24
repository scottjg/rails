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

      def installed?
        File.directory?(path)
      end

      def install(options = {})
        raise NotImplementedError, "The base Plugin does not implement plugin installation."
      end

      protected

        def extract_name
          File.basename(uri)
        end
    end
  end
end
