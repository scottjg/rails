module Rails 
  
  # Check for valid Ruby version
  # This is done in an external file, so we can use it
  # from the `rails` program as well without duplication.
  class CheckRubyVersion < Initializer
    def self.run
      require 'ruby_version_check'
    end
  end
  
  # If Rails is vendored and RubyGems is available, install stub GemSpecs
  # for Rails, Active Support, Active Record, Action Pack, Action Mailer, and
  # Active Resource. This allows Gem plugins to depend on Rails even when
  # the Gem version of Rails shouldn't be loaded.
  class InstallGemSpecStubs < Initializer
    def self.run
      unless Rails.respond_to?(:vendor_rails?)
        abort %{Your config/boot.rb is outdated: Run "rake rails:update".}
      end

      if Rails.vendor_rails?
        begin; require "rubygems"; rescue LoadError; return; end

        stubs = %w(rails activesupport activerecord actionpack actionmailer activeresource)
        stubs.reject! { |s| Gem.loaded_specs.key?(s) }

        stubs.each do |stub|
          Gem.loaded_specs[stub] = Gem::Specification.new do |s|
            s.name = stub
            s.version = Rails::VERSION::STRING
            s.loaded_from = ""
          end
        end
      end
    end
  end # InstallGemSpecStubs
  
  # Set the <tt>$LOAD_PATH</tt> based on the value of
  # Configuration#load_paths. Duplicates are removed.
  class SetLoadPath < Initializer
    def self.run
      load_paths = configuration.load_paths + configuration.framework_paths
      load_paths.reverse_each { |dir| $LOAD_PATH.unshift(dir) if File.directory?(dir) }
      $LOAD_PATH.uniq!
    end
  end
  
  class AddGemLoadPath < Initializer
    def self.run
      Rails::GemDependency.add_frozen_gem_path
      unless configuration.gems.empty?
        require "rubygems"
        configuration.gems.each { |gem| gem.add_load_paths }
      end
    end
  end
  
  # Requires all frameworks specified by the Configuration#frameworks
  # list. By default, all frameworks (Active Record, Active Support,
  # Action Pack, Action Mailer, and Active Resource) are loaded.
  class RequireFrameworks < Initializer
    def self.run
      configuration.frameworks.each { |framework| require(framework.to_s) }
      rescue LoadError => e
        # Re-raise as RuntimeError because Mongrel would swallow LoadError.
        raise e.to_s
    end
  end
    
  # Preload all frameworks specified by the Configuration#frameworks.
  # Used by Passenger to ensure everything's loaded before forking and
  # to avoid autoload race conditions in JRuby.
  class PreloadFrameworks < Initializer
    def self.run
      if configuration.preload_frameworks
        configuration.frameworks.each do |framework|
          # String#classify and #constantize aren't available yet.
          toplevel = Object.const_get(framework.to_s.gsub(/(?:^|_)(.)/) { $1.upcase })
          toplevel.load_all!
        end
      end
    end
  end # PreloadFrameworks

  # Set the paths from which Rails will automatically load source files, and
  # the load_once paths.
  class SetAutoloadPaths < Initializer
    def self.run
      ActiveSupport::Dependencies.load_paths = configuration.load_paths.uniq
      ActiveSupport::Dependencies.load_once_paths = configuration.load_once_paths.uniq

      extra = ActiveSupport::Dependencies.load_once_paths - ActiveSupport::Dependencies.load_paths
      unless extra.empty?
        abort <<-end_error
          load_once_paths must be a subset of the load_paths.
          Extra items in load_once_paths: #{extra * ','}
        end_error
      end

      # Freeze the arrays so future modifications will fail rather than do nothing mysteriously
      Rails.configuration.load_once_paths.freeze
    end
  end

  # Adds all load paths from plugins to the global set of load paths, so that
  # code from plugins can be required (explicitly or automatically via ActiveSupport::Dependencies).
  class AddPluginLoadPaths < Initializer
    def self.run
      plugin_loader.add_plugin_load_paths
    end
    
    def self.plugin_loader
      configuration.plugin_loader.new
    end
  end # AddPluginLoadPaths

  # Loads the environment specified by Configuration#environment_path, which
  # is typically one of development, test, or production.
  class LoadEnvironment < Initializer
    def self.run
      silence_warnings do
        return if @environment_loaded
        @environment_loaded = true

        # Setting up the differences in classes  is for reloading constants 
        # into Object out of this bootloader
        # So that any constants declared in it are put out to Object
        config = configuration
        constants = self.class.constants

        eval(IO.read(configuration.environment_path), binding, configuration.environment_path)

        (self.class.constants - constants).each do |const|
          Object.const_set(const, self.class.const_get(const))
        end
      end
    end
  end # LoadEnvironment

  # For Ruby 1.8, this initialization sets $KCODE to 'u' to enable the
  # multibyte safe operations. Plugin authors supporting other encodings
  # should override this behaviour and set the relevant +default_charset+
  # on ActionController::Base.
  #
  # For Ruby 1.9, this does nothing. Specify the default encoding in the Ruby
  # shebang line if you don't want UTF-8.
  class InitializeEncoding < Initializer
    def self.run
      $KCODE='u' if RUBY_VERSION < '1.9'
    end
  end
  
  # This initialization routine does nothing unless <tt>:active_record</tt>
  # is one of the frameworks to load (Configuration#frameworks). If it is,
  # this sets the database configuration from Configuration#database_configuration
  # and then establishes the connection.
  class InitializeDatabase < Initializer
    def self.run
      if configuration.frameworks.include?(:active_record)
        ActiveRecord::Base.configurations = configuration.database_configuration
        ActiveRecord::Base.establish_connection
      end
    end
  end
  
  class InitializeCache < Initializer
    def self.run
      unless defined?(RAILS_CACHE)
        silence_warnings { Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store(configuration.cache_store) }
      end
    end
  end # InitializeCache

  class InitializeFrameworkCaches < Initializer 
    def self.run
      if configuration.frameworks.include?(:action_controller)
        ActionController::Base.cache_store ||= RAILS_CACHE
      end
    end
  end
  
  # If the RAILS_DEFAULT_LOGGER constant is already set, this initialization
  # routine does nothing. If the constant is not set, and Configuration#logger
  # is not +nil+, this also does nothing. Otherwise, a new logger instance
  # is created at Configuration#log_path, with a default log level of
  # Configuration#log_level.
  #
  # If the log could not be created, the log will be set to output to
  # +STDERR+, with a log level of +WARN+.
  class InitializeLogger < Initializer
    def self.run
      # if the environment has explicitly defined a logger, use it
      return if Rails.logger

      unless logger = configuration.logger
        begin
          logger = ActiveSupport::BufferedLogger.new(configuration.log_path)
          logger.level = ActiveSupport::BufferedLogger.const_get(configuration.log_level.to_s.upcase)
          if configuration.environment == "production"
            logger.auto_flushing = false
          end
        rescue StandardError => e
          logger = ActiveSupport::BufferedLogger.new(STDERR)
          logger.level = ActiveSupport::BufferedLogger::WARN
          logger.warn(
            "Rails Error: Unable to access log file. Please ensure that #{configuration.log_path} exists and is chmod 0666. " +
            "The log level has been raised to WARN and the output directed to STDERR until the problem is fixed."
          )
        end
      end

      silence_warnings { Object.const_set "RAILS_DEFAULT_LOGGER", logger }
    end
  end # InitializeLogger
  
  # Sets the logger for Active Record, Action Controller, and Action Mailer
  # (but only for those frameworks that are to be loaded). If the framework's
  # logger is already set, it is not changed, otherwise it is set to use
  # RAILS_DEFAULT_LOGGER.
  class InitializeFramewordLogging < Initializer
    def self.run
      for framework in ([ :active_record, :action_controller, :action_mailer ] & configuration.frameworks)
        framework.to_s.camelize.constantize.const_get("Base").logger ||= Rails.logger
      end

      ActiveSupport::Dependencies.logger ||= Rails.logger
      Rails.cache.logger ||= Rails.logger
    end
  end  # InitializeFrameworkLogging
  
  
  # Sets the dependency loading mechanism based on the value of
  # Configuration#cache_classes.
  class InitializeDependencyMechanism < Initializer
    def self.run
      ActiveSupport::Dependencies.mechanism = configuration.cache_classes ? :require : :load
    end
  end # InitializeDependencyMechanism
  
  # Loads support for "whiny nil" (noisy warnings when methods are invoked
  # on +nil+ values) if Configuration#whiny_nils is true.
  class InitializeWhinyNils < Initializer
    def self.run
      require('active_support/whiny_nil') if configuration.whiny_nils
    end
  end
  
  # Sets the default value for Time.zone, and turns on ActiveRecord::Base#time_zone_aware_attributes.
  # If assigned value cannot be matched to a TimeZone, an exception will be raised.
  class InitializeTimeZone < Initializer
    def self.run
      if configuration.time_zone
        zone_default = Time.__send__(:get_zone, configuration.time_zone)

        unless zone_default
          raise \
            'Value assigned to config.time_zone not recognized.' +
            'Run "rake -D time" for a list of tasks for finding appropriate time zone names.'
        end

        Time.zone_default = zone_default

        if configuration.frameworks.include?(:active_record)
          ActiveRecord::Base.time_zone_aware_attributes = true
          ActiveRecord::Base.default_timezone = :utc
        end
      end
    end
  end # InitializeTimeZone
    
  # Set the i18n configuration from config.i18n but special-case for the load_path which should be
  # appended to what's already set instead of overwritten.
  class InitializeI18n < Initializer
    def self.run
      configuration.i18n.each do |setting, value|
        if setting == :load_path
          I18n.load_path += value
        else
          I18n.send("#{setting}=", value)
        end
      end
    end
  end # InitializeI18n

  # Initializes framework-specific settings for each of the loaded frameworks
  # (Configuration#frameworks). The available settings map to the accessors
  # on each of the corresponding Base classes.
  class InitializeFrameworkSettings < Initializer
    def self.run
      configuration.frameworks.each do |framework|
        base_class = framework.to_s.camelize.constantize.const_get("Base")

        configuration.send(framework).each do |setting, value|
          base_class.send("#{setting}=", value)
        end
      end
      configuration.active_support.each do |setting, value|
        ActiveSupport.send("#{setting}=", value)
      end
    end
  end # InitializeFrameworkSettings
  
  # Sets +ActionController::Base#view_paths+ and +ActionMailer::Base#template_root+
  # (but only for those frameworks that are to be loaded). If the framework's
  # paths have already been set, it is not changed, otherwise it is
  # set to use Configuration#view_path.
  class InitializeFrameworkViews < Initializer
    def self.run
      if configuration.frameworks.include?(:action_view)
        view_path = ActionView::PathSet::Path.new(configuration.view_path, false)
        ActionMailer::Base.template_root ||= view_path if configuration.frameworks.include?(:action_mailer)
        ActionController::Base.view_paths = view_path if configuration.frameworks.include?(:action_controller) && ActionController::Base.view_paths.empty?
      end
    end
  end #InitializeFrameworkViews
  
  class InitializeMetal < Initializer
    def self.run
      configuration.middleware.use Rails::Rack::Metal
    end
  end # InitializeMetal
  
  # Add the load paths used by support functions such as the info controller
  class AddSupportLoadPaths < Initializer
    def self.run
      Rails::Initializer.add_support_load_paths if Rails::Initializer.respond_to?(:add_support_load_paths)
    end
  end # AddSupportLoadPaths
  
  class LoadGems < Initializer
    def self.run
      configuration.gems.each { |gem| gem.load }
    end
  end # LoadGems
  
  # Loads all plugins in <tt>config.plugin_paths</tt>.  <tt>plugin_paths</tt>
  # defaults to <tt>vendor/plugins</tt> but may also be set to a list of
  # paths, such as
  #   config.plugin_paths = ["#{RAILS_ROOT}/lib/plugins", "#{RAILS_ROOT}/vendor/plugins"]
  #
  # In the default implementation, as each plugin discovered in <tt>plugin_paths</tt> is initialized:
  # * its +lib+ directory, if present, is added to the load path (immediately after the applications lib directory)
  # * <tt>init.rb</tt> is evaluated, if present
  #
  # After all plugins are loaded, duplicates are removed from the load path.
  # If an array of plugin names is specified in config.plugins, only those plugins will be loaded
  # and they plugins will be loaded in that order. Otherwise, plugins are loaded in alphabetical
  # order.
  #
  # if config.plugins ends contains :all then the named plugins will be loaded in the given order and all other
  # plugins will be loaded in alphabetical order
  class LoadPlugins < Initializer
    def self.run
      AddPluginLoadPaths.plugin_loader.load_plugins
    end
  end
  
  class LoadPluginGemDepencencies < Initializer
    def self.run
      AddGemLoadPaths.run
      LoadGems.run
    end
  end
  
  class CheckGemDependencies < Initializer
    def self.run
      unloaded_gems = configuration.gems.reject { |g| g.loaded? }
      if unloaded_gems.size > 0
        configuration.gems_dependencies_loaded = false
        # don't print if the gems rake tasks are being run
        unless $rails_gem_installer
          abort <<-end_error
Missing these required gems:
  #{unloaded_gems.map { |gem| "#{gem.name}  #{gem.requirement}" } * "\n  "}

You're running:
  ruby #{Gem.ruby_version} at #{Gem.ruby}
  rubygems #{Gem::RubyGemsVersion} at #{Gem.path * ', '}

Run `rake gems:install` to install the missing gems.
          end_error
        end
      else
        configuration.gems_dependencies_loaded = true
      end
    end
  end # CheckGemDependencies
  
  
  class LoadApplicationInitializers < Initializer
    def self.run
      if configuration.gems_dependencies_loaded
        Dir["#{configuration.root_path}/config/initializers/**/*.rb"].sort.each do |initializer|
          load(initializer)
        end
      end
    end
  end # LoadApplicationInitializers

  # Fires the user-supplied after_initialize block (Configuration#after_initialize)
  class AfterInitialize < Initializer
    def self.run
      if configuration.gems_dependencies_loaded
        configuration.after_initialize_blocks.each do |block|
          block.call
        end
      end
    end
  end # AfterInitialize
  
  class PrepareDispatcher < Initializer
    def self.run
      return unless configuration.frameworks.include?(:action_controller)
      require 'dispatcher' unless defined?(::Dispatcher)
      Dispatcher.define_dispatcher_callbacks(configuration.cache_classes)
      Dispatcher.new(Rails.logger).send :run_callbacks, :prepare_dispatch
    end
  end
  
  # If Action Controller is not one of the loaded frameworks (Configuration#frameworks)
  # this does nothing. Otherwise, it loads the routing definitions and sets up
  # loading module used to lazily load controllers (Configuration#controller_paths).
  class InitializeRouting < Initializer
    def self.run
      return unless configuration.frameworks.include?(:action_controller)
      ActionController::Routing.controller_paths += configuration.controller_paths
      ActionController::Routing::Routes.add_configuration_file(configuration.routes_configuration_file)
      ActionController::Routing::Routes.reload
    end
  end
  
  # Observers are loaded after plugins in case Observers or observed models are modified by plugins.
  class LoadObservers < Initializer
    def self.run
      if configuration.gems_dependencies_loaded && configuration.frameworks.include?(:active_record)
        ActiveRecord::Base.instantiate_observers
      end
    end
  end
  
  class LoadViewPaths < Initializer
    def self.run
      if configuration.frameworks.include?(:action_view)
        if configuration.cache_classes
          ActionController::Base.view_paths.load if configuration.frameworks.include?(:action_controller)
          ActionMailer::Base.template_root.load if configuration.frameworks.include?(:action_mailer)
        end
      end
    end
  end
  
  # Eager load application classes
  class LoadApplicationClasses < Initializer
    def self.run
      if configuration.cache_classes
        configuration.eager_load_paths.each do |load_path|
          matcher = /\A#{Regexp.escape(load_path)}(.*)\.rb\Z/
          Dir.glob("#{load_path}/**/*.rb").sort.each do |file|
            require_dependency file.sub(matcher, '\1')
          end
        end
      end      
    end
  end
  
  # Disable dependency loading during request cycle
  class DisableDependencyLoading < Initializer
    def self.run
      if configuration.cache_classes && !configuration.dependency_loading
        ActiveSupport::Dependencies.unhook!
      end
    end
  end
  
  # Mark Rails as being initialized
  class FlagInitialization < Initializer
    def self.run
      Rails.initialized = true
    end
  end
end # Rails