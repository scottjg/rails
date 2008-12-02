require 'switchboard'

module ActiveResource
  class Base
    class << self
      def delete(id, options = {})
        connection.delete(collection_path(options), id)
      end

      def exists?(id, options = {})
        if id
          prefix_options, query_options = split_options(options[:params])
          path = element_path(id, prefix_options, query_options)
          response = connection.head(path, headers)
          true
        end
        # id && !find_single(id, options).nil?
      rescue ActiveResource::ResourceNotFound
        false
      end

      def element_path(id, prefix_options = {}, query_options = nil)
        # puts "element_path for #{id}, #{prefix_options.inspect}, #{query_options.inspect}"
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}#{collection_name}/#{id}"
      end

      def collection_path(prefix_options = {}, query_options = nil)
        # puts "collection_path for #{prefix_options.inspect}, #{query_options.inspect}"
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}#{collection_name}"
      end
    end

    def destroy
      connection.delete(collection_path, to_param, self.class.headers)
    end

    # Update the resource on the remote service.
    def update
      returning connection.put(collection_path(prefix_options), to_param, encode, self.class.headers) do |response|
        load_attributes_from_response(response)
      end
    end
  end

  class XmppConnection < Connection
    attr_reader :switchboard

    def initialize(site, format = nil)
      super

      settings = {
        "jid"           => "client@memberfresh-lm.local",
        "password"      => "client",
        "pubsub.server" => site.host
      }

      puts "Switchboard settings: #{settings.inspect}"

      @switchboard = Switchboard::Client.new(settings)
      @switchboard.plug!(PubSubJack)

      # start the switchboard in a separate thread
      Thread.new do
        @switchboard.run!
      end

      # TODO note that this is synchronous and will block
      sleep 0.1 until switchboard.ready?
    end

    #
    def host
      site.host
    end

    # Execute a DELETE request.
    # Used to delete resources.
    def delete(path, id, headers = {})
      request(:retract, path, id)
    end

    # Execute a GET request.
    # Used to get (find) resources.
    def get(path, headers = {})
      format.decode(request(:items, path))
    end

    # Execute a HEAD request.
    # Used to obtain meta-information about resources, such as whether they exist and their size (via response headers).
    def head(path, headers = {})
      request(:items, path)
    end

    # Execute a POST request.
    # Used to create new resources.
    def post(path, body = '', headers = {})
      request(:publish, path, body.to_s)
    end

    # Execute a PUT request.
    # Used to update resources.
    def put(path, id, body = '', headers = {})
      request(:publish_with_id, path, id, body.to_s)
    end

  private

    # Makes request to remote service.
    def request(method, path, *arguments)
      logger.info "#{method.to_s.upcase} #{site.scheme}://#{[site.host, site.port].compact * ":"}#{path}" if logger
      result = nil

      time = Benchmark.realtime do
        case method
        when :items
          begin
            # TODO limit queries can be handled as the second argument to Client#get_items_from
            items = switchboard.get_items_from(path)

            if items.length > 1
              # fake-out instantiate_collection
              result = "<stuff type='array'>#{items.values.join("\n")}</stuff>"
            elsif items.length == 1
              result = items.values.first.to_s
            end
          rescue Jabber::ServerError => e
            # puts "Error: #{e.error}"
            raise(ResourceNotFound.new(nil))
          end
        when :publish
          puts "Publishing item to #{path}"

          item = Jabber::PubSub::Item.new
          item.text = arguments.shift

          # this is asynchronous, so we don't know the id immediately
          switchboard.publish_item_to(path, item)

          result = item.text
        when :publish_with_id
          id = arguments.shift
          puts "Publishing item to #{path} with id '#{id}'"

          item = Jabber::PubSub::Item.new
          item.text = arguments.shift

          # this is asynchronous, so we don't know the id immediately
          switchboard.publish_item_with_id_to(path, item, id)

          result = item.text
        when :retract
          id = arguments.shift
          puts "Retracting item from #{path} with id '#{id}'"

          switchboard.delete_item_from(path, id)
        else
          logger.warn "unsupported method: #{method}"
        end
      end

      logger.info "--> (%.2fs)" % time if logger

      # TODO rescue from Jabber::ServerErrors (or Jabber::Error)
      result

    # TODO nothing will raise a timeout error
    rescue Timeout::Error => e
      raise TimeoutError.new(e.message)
    end
  end
end
