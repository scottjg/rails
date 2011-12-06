module Rails
  class Application
    module Finisher
      include Initializable
      $rails_rake_task = nil

      # Sets the dependency loading mechanism.
      # TODO: Remove files from the $" and always use require.
      initializer :initialize_dependency_mechanism, :group => :all do
        ActiveSupport::Dependencies.mechanism = config.cache_classes ? :require : :load
      end

      initializer :set_all_autoload_paths do
        ActiveSupport::Dependencies.autoload_paths.concat(config.all_autoload_paths)
        ActiveSupport::Dependencies.autoload_once_paths.concat(config.all_autoload_once_paths)
      end

      initializer :before_initializers_hook do
        ActiveSupport.run_load_hooks(:before_initializers, self)
      end

      initializer :load_init_rb do
        config.all_eval_initializers.each do |init_rb|
          eval(File.read(init_rb), binding, init_rb)
        end
      end

      initializer :load_config_initializers do
        config.all_initializers.each { |init| load(init) }
      end

      initializer :after_initializers_hook do
        ActiveSupport.run_load_hooks(:after_initializers, self)
      end

      initializer :add_generator_templates do
        config.generators.templates.unshift(*paths["lib/templates"].existent)
      end

      initializer :ensure_autoload_once_paths_as_subset do
        extra = ActiveSupport::Dependencies.autoload_once_paths -
                ActiveSupport::Dependencies.autoload_paths

        unless extra.empty?
          abort <<-end_error
            autoload_once_paths must be a subset of the autoload_paths.
            Extra items in autoload_once_paths: #{extra * ','}
          end_error
        end
      end

      initializer :add_to_prepare_blocks do
        config.to_prepare_blocks.each do |block|
          ActionDispatch::Reloader.to_prepare(&block)
        end
      end

      initializer :add_builtin_route do |app|
        if Rails.env.development?
          app.routes.append do
            match '/rails/info/properties' => "rails/info#properties"
          end
        end
      end

      initializer :build_middleware_stack do
        build_middleware_stack
      end

      initializer :define_main_app_helper do |app|
        app.routes.define_mounted_helper(:main_app)
      end

      initializer :run_prepare_callbacks do
        ActionDispatch::Reloader.prepare!
      end

      initializer :eager_load! do
        if config.cache_classes && !$rails_rake_task
          ActiveSupport.run_load_hooks(:before_eager_load, self)
          eager_load!
        end
      end

      initializer :finisher_hook do
        ActiveSupport.run_load_hooks(:after_initialize, self)
      end

      # Force routes to be loaded just at the end and add it to to_prepare callbacks
      # This needs to be after the finisher hook to ensure routes added in the hook
      # are still loaded.
      initializer :set_routes_reloader do |app|
        reloader = lambda { app.routes_reloader.execute_if_updated }
        reloader.call
        ActionDispatch::Reloader.to_prepare(&reloader)
      end

      # Disable dependency loading during request cycle
      initializer :disable_dependency_loading do
        if config.cache_classes && !config.dependency_loading
          ActiveSupport::Dependencies.unhook!
        end
      end
    end
  end
end
