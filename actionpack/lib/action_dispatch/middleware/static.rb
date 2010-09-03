require 'rack/utils'

module ActionDispatch
  class Static
    FILE_METHODS = %w(GET HEAD).freeze

    def initialize(app, roots)
      @app = app
      @roots = normalize_roots(roots)
      @file_servers = create_file_servers
    end

    def call(env)
      path   = env['PATH_INFO'].chomp('/')
      method = env['REQUEST_METHOD']

      if FILE_METHODS.include?(method)
        ext = ::ActionController::Base.page_cache_extension

        @roots.each do |at, root|
          if at == "" || path =~ /^#{at}/
            full_path = File.join(root, ::Rack::Utils.unescape(path.sub(/^#{at}/, "")))
            paths = "{#{[full_path, "#{full_path}#{ext}", "#{full_path}/index#{ext}"].join(",")}}"

            matches = Dir[paths]
            unless matches.blank?
              match = matches.detect { |m| File.file?(m) }
              if match
                env["PATH_INFO"] = match.sub(/^#{root}/, '')
                return @file_servers[at].call(env)
              end
            end
          end
        end
      end

      @app.call(env)
    end

    private
      def normalize_roots(roots)
        roots = { "" => roots.chomp("/") } unless roots.is_a?(Hash)

        new_roots = ActiveSupport::OrderedHash.new
        roots.each do |at, root|
          new_roots[at.chomp('/')] = root if File.directory?(root)
        end

        new_roots
      end

      def create_file_servers
        servers = {}
        @roots.each do |at, root|
          servers[at] = ::Rack::File.new(root)
        end

        servers
      end
  end
end
