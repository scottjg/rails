$:.unshift File.dirname(__FILE__) + "/../lib"

require 'plugin_manager/plugin'

module Rails
  module PluginManager
    class GitPlugin < Plugin
      def install(options = {})
        method = options[:method] || :checkout

        case method
        when :checkout
          install_using_checkout(options)
        when :submodule
          install_using_submodule(options)
        else
          raise ArgumentError, "Cannot install the plugin #{name} using Git with the method `#{method}`"
        end
      end

      def remove(options = {})
        if installed_as_submodule?
          puts "Removing from .gitmodules" unless options[:quiet]
          system(%(git config -f .gitmodules --remove-section submodule."#{path}"))
        end
      end

      def extract_name
        super.gsub(/\.git$/, '')
      end

      def self.supported_uri_schemes
        [:git]
      end

      protected

        def install_using_checkout(options)
          mkdir_p path
          Dir.chdir path do
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
              rm_rf path
            end
          end
        end

        def install_using_submodule(options)
          base_cmd = "git submodule add #{uri} #{path}"
          puts base_cmd if $verbose
          if not system(base_cmd)
            rm_rf path
          end
        end

        def installed_as_submodule?
          `git submodule`.split(/\n/).any? { |line| line =~ /#{path}$/ }
        end
    end

    PluginManager.add_plugin_implementation(GitPlugin)
  end
end
