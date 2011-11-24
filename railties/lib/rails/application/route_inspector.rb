module Rails
  class Application
    ##
    # This class is just used for displaying route information when someone
    # executes `rake routes`.  People should not use this class.
    class RouteInspector # :nodoc:
      def format all_routes, filter = nil
        if filter
          all_routes = all_routes.select{ |route| route.defaults[:controller] == filter }
        end

        routes = collect_routes(all_routes)

        for_display(routes)
      end

      def collect_routes(routes)
        routes = routes.collect do |route|
          route_reqs = route.requirements

          rack_app = route.app unless route.app.class.name.to_s =~ /^ActionDispatch::Routing/

          controller = route_reqs[:controller] || ':controller'
          action     = route_reqs[:action]     || ':action'

          endpoint = rack_app ? rack_app.inspect : "#{controller}##{action}"
          constraints = route_reqs.except(:controller, :action)

          reqs = endpoint
          reqs += " #{constraints.inspect}" unless constraints.empty?

          verb = route.verb.source.gsub(/[$^]/, '')

          children = children(rack_app)

          {:name => route.name.to_s, :verb => verb, :path => route.path.spec.to_s, :reqs => reqs, :children => children }
        end

        # Skip the route if it's internal info route
        routes.reject { |r| r[:path] =~ %r{/rails/info/properties|^/assets} }
      end

      def children(rack_app)
        return unless rack_app && ENV["ENGINES"]
        rack_app = rack_app.instance if rack_app.respond_to?(:instance)

        if rack_app.kind_of?(Rails::Engine)
          collect_routes(rack_app.routes.routes)
        end
      end

      def for_display(routes, depth = 0)
        name_width = routes.map{ |r| r[:name].length }.max
        verb_width = routes.map{ |r| r[:verb].length }.max
        path_width = routes.map{ |r| r[:path].length }.max
        indent     = " " * (4 * depth)

        routes.map do |r|
          result = "#{indent}#{r[:name].rjust(name_width)} #{r[:verb].ljust(verb_width)} #{r[:path].ljust(path_width)} #{r[:reqs]}"

          if r[:children]
            name = "#{" " * (4 * (depth + 1))}#{r[:reqs]}:"
            [result, name, for_display(r[:children], depth + 1)]
          else
            result
          end
        end.flatten
      end
    end
  end
end
