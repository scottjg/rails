
module Rails::PluginManager
  module Commands
    include Helpers

    def install(uri, options = {})
      manager = find_plugin_manager(uri)
      name = options[:name] || manager.extract_name(uri)
      manager.install(uri, name, options)
      run_install_hook(name)
    end

    def remove(name, options = {})
      manager = managers.values.find {|manager| manager.has_installed?(name) }
      if manager
        manager.new.remove(name)
      else
        raise "No plugin manager was able to remove #{name}"
        # TODO: use a FileSystemPluginManager or something.
      end
    end

    def installed?(name_or_uri)
      File.directory?(install_path(name_or_uri)) ||
        managers.values.any? {|manager| manager.has_installed?(name_or_uri) }
    end

    def find_plugin_manager(uri)
      scheme = URI.parse(uri).scheme
      manager = managers[scheme.to_sym]
      if manager.nil?
        raise ArgumentError, "No Plugin Manager installed for the URI scheme `#{scheme}`"
      end
      manager
    end

    def add_plugin_manager(uri_scheme, manager)
      managers[uri_scheme.to_sym] = manager
    end

    private
      def managers
        @managers ||= {}
      end

      def run_install_hook(name)
        install_hook_file = "#{install_path(name)}/install.rb"
        load install_hook_file if File.exist? install_hook_file
      end

      def run_uninstall_hook
        uninstall_hook_file = "#{install_path(name)}/uninstall.rb"
        load uninstall_hook_file if File.exist? uninstall_hook_file
      end
  end
end
