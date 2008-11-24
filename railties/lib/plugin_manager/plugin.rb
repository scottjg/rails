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
        if installed?
          puts "Running install hooks for the plugin" unless options[:quiet]
          run_install_hook
        else
          raise StandardError, "The base Plugin implementation cannot install a plugin."
        end
      end

      def remove(options = {})
        puts "Running uninstall hooks for the plugin" unless options[:quiet]
        run_uninstall_hook

        puts "Removing #{install_path(name)}" unless options[:quiet]
        rm_rf path
      end

      protected

        def extract_name
          File.basename(uri)
        end

        def run_install_hook
          install_hook_file = "#{path}/install.rb"
          load install_hook_file if File.exist? install_hook_file
        end

        def run_uninstall_hook
          uninstall_hook_file = "#{path}/uninstall.rb"
          load uninstall_hook_file if File.exist? uninstall_hook_file
        end
    end
  end
end
