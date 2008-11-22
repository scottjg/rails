$verbose = true

class GitPluginManager < Rails::PluginManager::Base

  def install(uri, name, options = {})
    case options[:method]
    when :checkout, nil
      install_using_checkout(uri, name, options)
    when :submodule
      install_using_submodule(uri, name, options)
    else
      raise ArgumentError, "Cannot install the plugin #{name} using Git with the method `#{options[:method]}`"
    end
  end

  def extract_name(uri)
    File.basename(uri).gsub(/\.git$/, '')
  end

  protected

    def install_using_checkout(uri, name, options)
      install_path = mkdir_p "#{plugins_dir}/#{name}"
      Dir.chdir install_path do
        init_cmd = "git init"
        init_cmd += " -q" if options[:quiet] and not $verbose
        puts init_cmd if $verbose
        system(init_cmd)
        base_cmd = "git pull --depth 1 #{uri}"
        base_cmd += " -q" if options[:quiet] and not $verbose
        base_cmd += " #{options[:revision]}" if options[:revision]
        puts base_cmd if $verbose
        if system(base_cmd)
          puts "removing: .git" if $verbose
          rm_rf ".git"
        else
          rm_rf install_path
        end
      end
    end

    def install_using_submodule(uri, name, options)
      install_path = "#{plugins_dir}/#{name}"
      base_cmd = "git submodule add #{uri} #{relative_plugins_dir}/#{name}"
      puts base_cmd if $verbose
      if not system(base_cmd)
        rm_rf install_path
      end
    end
end

Rails::PluginManager.add_plugin_manager(:git, GitPluginManager)
