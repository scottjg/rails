require 'action_dispatch/http/request'

module ActionDispatch
  module Routing
    module Redirection

      # Redirect any path to another path:
      #
      #   match "/stories" => redirect("/posts")
      def redirect(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        status  = options.delete(:status) || 301

        path = args.shift

        path_proc = if path.is_a?(String)
          proc { |params| (params.empty? || !path.match(/%\{\w*\}/)) ? path : (path % params) }
        elsif options.any?
          options_proc(options)
        elsif path.respond_to?(:call)
          proc { |params, request| path.call(params, request) }
        elsif block
          block
        else
          raise ArgumentError, "redirection argument not supported"
        end

        redirection_proc(status, path_proc)
      end

      private

        def options_proc(options)
          proc do |params, request|
            path = if options[:path].nil?
              request.path
            elsif params.empty? || !options[:path].match(/%\{\w*\}/)
              options.delete(:path)
            else
              (options.delete(:path) % params)
            end

            request.url_with(options.reverse_merge(:path => path))
          end
        end

        def redirection_proc(status, path_proc)
          lambda do |env|
            req = Request.new(env)

            params = [req.symbolized_path_parameters]
            params << req if path_proc.arity > 1

            uri = URI.parse(path_proc.call(*params))
            uri.scheme ||= req.scheme
            uri.host   ||= req.host
            uri.port   ||= req.port unless req.standard_port?

            body = %(<html><body>You are being <a href="#{ERB::Util.h(uri.to_s)}">redirected</a>.</body></html>)

            headers = {
              'Location' => uri.to_s,
              'Content-Type' => 'text/html',
              'Content-Length' => body.length.to_s
            }

            [ status, headers, [body] ]
          end
        end

    end
  end
end