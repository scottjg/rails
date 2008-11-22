
module Rails::PluginManager
  module Commands
    def install(uri, options = {})
      manager = find_plugin_manager(uri)
      name = options[:name] || manager.extract_name(uri)
      manager.install(uri, name, options)
    end

    def remove(name, options = {})
      manager = @managers.values.find {|manager| manager.new.has_installed?(name) }
      if manager
        manager.new.remove(name)
      else
        raise "No plugin manager was able to remove #{name}"
        # TODO: use a FileSystemPluginManager or something.
      end
    end

    def find_plugin_manager(uri)
      scheme = URI.parse(uri).scheme
      manager = @managers[scheme.to_sym]
      if manager.nil?
        raise ArgumentError, "No Plugin Manager installed for the URI scheme `#{scheme}`"
      end
      manager.new
    end

    def add_plugin_manager(uri_scheme, manager)
      @managers ||= {}
      @managers[uri_scheme.to_sym] = manager
    end
  end
end
