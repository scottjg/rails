$verbose = true

class GitPluginManager < Rails::PluginManager::Base
  def install(uri, name, options = {})
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

  def extract_name(uri)
    File.basename(uri).gsub(/\.git$/, '')
  end
end

Rails::PluginManager.add_plugin_manager(:git, GitPluginManager)
