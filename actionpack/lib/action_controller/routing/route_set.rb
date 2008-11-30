module ActionController
  module Routing
    class RouteSet #:nodoc:
      # Mapper instances are used to build routes. The object passed to the draw
      # block in config/routes.rb is a Mapper instance.
      #
      # Mapper instances have relatively few instance methods, in order to avoid
      # clashes with named routes.
      class Mapper #:doc:
        include ActionController::Resources

        def initialize(set) #:nodoc:
          @set = set
        end

        # Create an unnamed route with the provided +path+ and +options+. See
        # ActionController::Routing for an introduction to routes.
        def connect(path, options = {})
          @set.add_route(path, options)
        end

        # Creates a named route called "root" for matching the root level request.
        def root(options = {})
          if options.is_a?(Symbol)
            if source_route = @set.named_routes.routes[options]
              options = source_route.defaults.merge({ :conditions => source_route.conditions })
            end
          end
          named_route("root", '', options)
        end

        def named_route(name, path, options = {}) #:nodoc:
          @set.add_named_route(name, path, options)
        end

        # Enables the use of resources in a module by setting the name_prefix, path_prefix, and namespace for the model.
        # Example:
        #
        #   map.namespace(:admin) do |admin|
        #     admin.resources :products,
        #       :has_many => [ :tags, :images, :variants ]
        #   end
        #
        # This will create +admin_products_url+ pointing to "admin/products", which will look for an Admin::ProductsController.
        # It'll also create +admin_product_tags_url+ pointing to "admin/products/#{product_id}/tags", which will look for
        # Admin::TagsController.
        def namespace(name, options = {}, &block)
          if options[:namespace]
            with_options({:path_prefix => "#{options.delete(:path_prefix)}/#{name}", :name_prefix => "#{options.delete(:name_prefix)}#{name}_", :namespace => "#{options.delete(:namespace)}#{name}/" }.merge(options), &block)
          else
            with_options({:path_prefix => name, :name_prefix => "#{name}_", :namespace => "#{name}/" }.merge(options), &block)
          end
        end

        def method_missing(route_name, *args, &proc) #:nodoc:
          super unless args.length >= 1 && proc.nil?
          @set.add_named_route(route_name, *args)
        end
      end

      # A NamedRouteCollection instance is a collection of named routes, and also
      # maintains an anonymous module that can be used to install helpers for the
      # named routes.
      class NamedRouteCollection #:nodoc:
        include Enumerable
        include ActionController::Routing::Optimisation
        attr_reader :routes, :helpers

        def initialize
          clear!
        end

        def clear!
          @routes = {}
          @helpers = []

          @module ||= Module.new
          @module.instance_methods(false).each do |selector|
            @module.class_eval { remove_method selector }
          end
          @module.send :include, UrlHelperMixin
        end

        def add(name, route)
          name = name.to_sym
          routes[name.to_sym] = route
          define_named_route_methods(name)
        end

        def get(name)
          routes[name.to_sym]
        end

        alias []=   add
        alias []    get
        alias clear clear!

        def each
          routes.each { |name, route| yield name, route }
          self
        end

        def names
          routes.keys
        end

        def length
          routes.length
        end

        def reset!
          old_routes = routes.dup
          clear!
          old_routes.each do |name, route|
            add(name, route)
          end
        end

        def install(destinations = [ActionController::Base, ActionView::Base], regenerate = false)
          reset! if regenerate
          Array(destinations).each do |dest|
            dest.__send__(:include, @module)
          end
        end

        private
          def define_named_route_methods(name)
            define_hash_access name, :url
            define_hash_access name, :path
            define_url_helper name, :url
            define_url_helper name, :path
          end

          def named_helper_module_eval(code, *args)
            @module.module_eval(code, *args)
          end

          def define_hash_access(name, kind)
            selector = :"hash_for_#{name}_#{kind}"

            named_helper_module_eval <<-end_eval
              protected
                def #{selector}(options = nil)
                  generate_named_route_hash(:#{name}, :#{kind}, options)
                end
            end_eval

            helpers << selector
          end

          # allow ordered parameters to be associated with corresponding
          # dynamic segments, so you can do
          #
          #   foo_url(bar, baz, bang)
          #
          # instead of
          #
          #   foo_url(:bar => bar, :baz => baz, :bang => bang)
          #
          # Also allow options hash, so you can do
          #
          #   foo_url(bar, baz, bang, :sort_by => 'baz')
          #
          def define_url_helper(name, kind)
            selector = :"#{name}_#{kind}"

            named_helper_module_eval <<-end_eval
              protected
                def #{selector}(*args) generate_named_route(:#{name}, :#{kind}, *args) end
                def formatted_#{selector}(*args) deprecated_formatted_named_route(:#{selector}, *args) end
            end_eval

            helpers << selector
          end

          module UrlHelperMixin
            protected
              def generate_named_route(name, kind, *args)
                route = named_route_for(name)
                #generate_optimisation_block(route, kind)

                opts =
                  if args.empty?
                    {}
                  elsif args.first === Hash
                    args.first
                  else
                    options = args.extract_options!
                    args = args.zip(route.segment_keys).inject({}) do |h, (v, k)|
                      h[k] = v
                      h
                    end
                    options.merge(args)
                  end

                url_for(generate_named_route_hash(name, kind, opts))
              end

              def deprecated_formatted_named_route(selector, *args)
                ActiveSupport::Deprecation.warn("formatted_#{selector}() has been deprecated. please pass format to the standard #{selector}() method instead.", caller)
                send(selector, *args)
              end

              def generate_named_route_hash(name, kind, options)
                named_route_for(name).defaults.merge(:use_route => name, :only_path => kind == :path).merge(options || {})
              end

              def named_route_for(name)
                unless route_set = self.class.installed_route_set
                  raise "Missing #{name.inspect}: no route set is installed on #{self.class}"
                end

                unless route = route_set.named_routes.routes[name.to_sym]
                  raise "Missing #{name.inspect} in #{route_set.named_routes.routes.inspect}"
                end

                route
              end
          end
      end

      attr_accessor :routes, :named_routes, :configuration_files

      def initialize
        self.configuration_files = []

        self.routes = []
        self.named_routes = NamedRouteCollection.new

        clear_recognize_optimized!
      end

      # Subclasses and plugins may override this method to specify a different
      # RouteBuilder instance, so that other route DSL's can be created.
      def builder
        @builder ||= RouteBuilder.new
      end

      def draw
        yield Mapper.new(self)
        install_helpers
      end

      def clear!
        routes.clear
        named_routes.clear
        @installed_at.each { |c| c.installed_route_set = nil } if @installed_at
        @installed_at = nil
        @combined_regexp = nil
        @routes_by_controller = nil
        # This will force routing/recognition_optimization.rb
        # to refresh optimisations.
        clear_recognize_optimized!
      end

      def install_helpers(destinations = [ActionController::Base, ActionView::Base], regenerate_code = false)
        @installed_at = Array(destinations)
        @installed_at.each do |d|
          d.cattr_accessor :installed_route_set unless d.respond_to?(:installed_route_set=)
          d.installed_route_set = self
          d.module_eval { include Helpers }
        end
        named_routes.install(destinations, regenerate_code)
      end

      def empty?
        routes.empty?
      end

      def add_configuration_file(path)
        self.configuration_files << path
      end

      # Deprecated accessor
      def configuration_file=(path)
        add_configuration_file(path)
      end
      
      # Deprecated accessor
      def configuration_file
        configuration_files
      end

      def load!
        Routing.use_controllers!(nil) # Clear the controller cache so we may discover new ones
        clear!
        load_routes!
      end

      # reload! will always force a reload whereas load checks the timestamp first
      alias reload! load!

      def reload
        if configuration_files.any? && @routes_last_modified
          if routes_changed_at == @routes_last_modified
            return # routes didn't change, don't reload
          else
            @routes_last_modified = routes_changed_at
          end
        end

        load!
      end

      def load_routes!
        if configuration_files.any?
          configuration_files.each { |config| load(config) }
          @routes_last_modified = routes_changed_at
        else
          add_route ":controller/:action/:id"
        end
      end
      
      def routes_changed_at
        routes_changed_at = nil
        
        configuration_files.each do |config|
          config_changed_at = File.stat(config).mtime

          if routes_changed_at.nil? || config_changed_at > routes_changed_at
            routes_changed_at = config_changed_at 
          end
        end
        
        routes_changed_at
      end

      def add_route(path, options = {})
        route = builder.build(path, options)
        routes << route
        route
      end

      def add_named_route(name, path, options = {})
        # TODO - is options EVER used?
        name = options[:name_prefix] + name.to_s if options[:name_prefix]
        named_routes[name.to_sym] = add_route(path, options)
      end

      def options_as_params(options)
        # If an explicit :controller was given, always make :action explicit
        # too, so that action expiry works as expected for things like
        #
        #   generate({:controller => 'content'}, {:controller => 'content', :action => 'show'})
        #
        # (the above is from the unit tests). In the above case, because the
        # controller was explicitly given, but no action, the action is implied to
        # be "index", not the recalled action of "show".
        #
        # great fun, eh?

        options_as_params = options.clone
        options_as_params[:action] ||= 'index' if options[:controller]
        options_as_params[:action] = options_as_params[:action].to_s if options_as_params[:action]
        options_as_params
      end

      def build_expiry(options, recall)
        recall.inject({}) do |expiry, (key, recalled_value)|
          expiry[key] = (options.key?(key) && options[key].to_param != recalled_value.to_param)
          expiry
        end
      end

      # Generate the path indicated by the arguments, and return an array of
      # the keys that were not used to generate it.
      def extra_keys(options, recall={})
        generate_extras(options, recall).last
      end

      def generate_extras(options, recall={})
        generate(options, recall, :generate_extras)
      end

      def generate(options, recall = {}, method=:generate)
        named_route_name = options.delete(:use_route)
        generate_all = options.delete(:generate_all)
        if named_route_name
          named_route = named_routes[named_route_name]
          options = named_route.parameter_shell.merge(options)
        end

        options = options_as_params(options)
        expire_on = build_expiry(options, recall)

        if options[:controller]
          options[:controller] = options[:controller].to_s
        end
        # if the controller has changed, make sure it changes relative to the
        # current controller module, if any. In other words, if we're currently
        # on admin/get, and the new controller is 'set', the new controller
        # should really be admin/set.
        if !named_route && expire_on[:controller] && options[:controller] && options[:controller][0] != ?/
          old_parts = recall[:controller].split('/')
          new_parts = options[:controller].split('/')
          parts = old_parts[0..-(new_parts.length + 1)] + new_parts
          options[:controller] = parts.join('/')
        end

        # drop the leading '/' on the controller name
        options[:controller] = options[:controller][1..-1] if options[:controller] && options[:controller][0] == ?/
        merged = recall.merge(options)

        if named_route
          path = named_route.generate(options, merged, expire_on)
          if path.nil?
            raise_named_route_error(options, named_route, named_route_name)
          else
            return path
          end
        else
          merged[:action] ||= 'index'
          options[:action] ||= 'index'

          controller = merged[:controller]
          action = merged[:action]

          raise RoutingError, "Need controller and action!" unless controller && action

          if generate_all
            # Used by caching to expire all paths for a resource
            return routes.collect do |route|
              route.__send__(method, options, merged, expire_on)
            end.compact
          end

          # don't use the recalled keys when determining which routes to check
          keys = options.keys.select { |k| options[k] }.sort_by(&:object_id)
          routes = routes_by_controller[controller][action][keys]

          routes.each do |route|
            results = route.__send__(method, options, merged, expire_on)
            return results if results && (!results.is_a?(Array) || results.first)
          end
        end

        raise RoutingError, "No route matches #{options.inspect}"
      end

      # try to give a helpful error message when named route generation fails
      def raise_named_route_error(options, named_route, named_route_name)
        diff = named_route.requirements.diff(options)
        unless diff.empty?
          raise RoutingError, "#{named_route_name}_url failed to generate from #{options.inspect}, expected: #{named_route.requirements.inspect}, diff: #{named_route.requirements.diff(options).inspect}"
        else
          required_segments = named_route.segments.select {|seg| (!seg.optional?) && (!seg.is_a?(DividerSegment)) }
          required_keys_or_values = required_segments.map { |seg| seg.key rescue seg.value } # we want either the key or the value from the segment
          raise RoutingError, "#{named_route_name}_url failed to generate from #{options.inspect} - you may have ambiguous routes, or you may need to supply additional parameters for this route.  content_url has the following required parameters: #{required_keys_or_values.inspect} - are they all satisfied?"
        end
      end

      def recognize(request)
        params = recognize_path(request.path, extract_request_environment(request))
        request.path_parameters = params.with_indifferent_access
        "#{params[:controller].camelize}Controller".constantize
      end

      def recognize_path(path, environment={})
        raise "Not optimized! Check that routing/recognition_optimisation overrides RouteSet#recognize_path."
      end

      def routes_by_controller
        @routes_by_controller ||= Hash.new do |controller_hash, controller|
          controller_hash[controller] = Hash.new do |action_hash, action|
            action_hash[action] = Hash.new do |key_hash, keys|
              key_hash[keys] = routes_for_controller_and_action_and_keys(controller, action, keys)
            end
          end
        end
      end

      def routes_for(options, merged, expire_on)
        raise "Need controller and action!" unless controller && action
        controller = merged[:controller]
        merged = options if expire_on[:controller]
        action = merged[:action] || 'index'

        routes_by_controller[controller][action][merged.keys.sort_by(&:object_id)]
      end

      def routes_for_controller_and_action(controller, action)
        selected = routes.select do |route|
          route.matches_controller_and_action? controller, action
        end
        (selected.length == routes.length) ? routes : selected
      end

      def routes_for_controller_and_action_and_keys(controller, action, keys)
        selected = routes.select do |route|
          route.matches_controller_and_action? controller, action
        end
        selected.sort_by do |route|
          (keys - route.significant_keys).length
        end
      end

      # Subclasses and plugins may override this method to extract further attributes
      # from the request, for use by route conditions and such.
      def extract_request_environment(request)
        { :method => request.method }
      end
    end
  end
end
