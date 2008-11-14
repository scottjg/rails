module ActiveSupport
  module Cache
    class HerokuMemCacheStore < MemCacheStore
      def initialize
        @addresses = [heroku_memcache_address]
        @data = Heroku.memcache
      end

      def heroku_memcache_address
        "#{Heroku.memcache.servers.first.host}:#{Heroku.memcache.servers.first.port}"
      end
    end
  end
end
