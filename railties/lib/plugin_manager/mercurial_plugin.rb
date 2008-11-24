$:.unshift File.dirname(__FILE__) + "/../lib"

module Rails
  module PluginManager
    class MercurialPlugin < Plugin
      def install(options = {})
        mkdir_p path
        Dir.chdir path do
          init_cmd = "hg init"
          init_cmd += " -q" if options[:quiet] and not $verbose
          puts init_cmd if $verbose
          system(init_cmd)
          base_cmd = "hg pull #{uri}"
          base_cmd += " -q" if options[:quiet] and not $verbose
          base_cmd += " -r #{options[:revision]}" if options[:revision]
          puts base_cmd if $verbose
          if system(base_cmd)
            system("hg update")
            puts "removing: .hg" if $verbose
            rm_rf ".hg"
          else
            rm_rf path
          end
        end
      end

      def remove(options = {})
      end

      def self.can_handle_uri?(uri)
        system("hg version -q") && system("hg id -r 000000 #{uri}")
      end
    end

    PluginManager.add_plugin_implementation(MercurialPlugin)
  end
end

