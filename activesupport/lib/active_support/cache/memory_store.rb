module ActiveSupport
  module Cache
    # A cache store implementation which stores everything into memory in the
    # same process. If you're running multiple Ruby on Rails server processes
    # (which is the case if you're using mongrel_cluster or Phusion Passenger),
    # then this means that your Rails server process instances won't be able
    # to share cache data with each other. If your application never performs
    # manual cache item expiry (e.g. when you're using generational cache keys),
    # then using MemoryStore is ok. Otherwise, consider carefully whether you
    # should be using this cache store.
    #
    # MemoryStore supports the :expires_in option. Because MemoryStore is often
    # used in testing environments, its implementation of :expires_in is compatible
    # with "time travel" libraries (e.g. Timecop). Specifically, time-traveling
    # to a point after the cache entry should expire, querying the cache for the
    # entry, and then time-traveling back to before expiration will result in
    # the entry still existing (or "existing again" depending on your frame
    # of reference.)
    #
    # MemoryStore is not only able to store strings, but also arbitrary Ruby
    # objects.
    #
    # MemoryStore is not thread-safe. Use SynchronizedMemoryStore instead
    # if you need thread-safety.
    class MemoryStore < Store
      def initialize
        @data = {} # of the form {key => [value, expires_at or nil]}
      end

      def read_multi(*names)
        results = {}
        names.each { |n| results[n] = read(n) }
        results
      end

      def read(name, options = nil)
        super
        value, expires_at = @data[name]
        if value && (expires_at.blank? || expires_at > Time.now)
          value
        else
          nil
        end
      end

      def write(name, value, options = nil)
        super
        expires_at = if options && options.respond_to?(:[]) && options[:expires_in]
          Time.now + options.delete(:expires_in)
        else
          nil
        end
        value.freeze.tap do |val|
          @data[name] = [value, expires_at]
        end
      end

      def delete(name, options = nil)
        super
        @data.delete(name)
      end

      def delete_matched(matcher, options = nil)
        super
        @data.delete_if { |k,v| k =~ matcher }
      end

      def exist?(name, options = nil)
        super
        _, expires_at = @data[name]
        @data.has_key?(name) && (expires_at.blank? || expires_at > Time.now)
      end

      def clear
        @data.clear
      end
    end
  end
end
