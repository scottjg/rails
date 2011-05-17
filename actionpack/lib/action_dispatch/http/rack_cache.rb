require "rack/cache"
require "rack/cache/context"
require "active_support/cache"

module ActionDispatch
  class RailsMetaStore < Rack::Cache::MetaStore
    def self.resolve(uri)
      new
    end

    # TODO: Finally deal with the RAILS_CACHE global
    def initialize(store = RAILS_CACHE)
      @store = store
    end
    
    # since #write does a Marshal.dump on the value
    # before writing it to the store, we need to
    # Marshal.load it after returning it from the store
    def read(key)
      if data = @store.read(key)
        Marshal.load(data)
      else
        []
      end
    end

    # Marshal.dump the value to do a 'deep_clone'
    # of the value so using MemoryStore doesn't cause
    # modifications to the value after it is read from the store
    # to persist across requests.  Fixes this issue:
    # https://github.com/rails/rails/issues/545
    def write(key, value)
      value = Marshal.dump(value)
      @store.write(key, value)
    end

    ::Rack::Cache::MetaStore::RAILS = self
  end

  class RailsEntityStore < Rack::Cache::EntityStore
    def self.resolve(uri)
      new
    end

    def initialize(store = RAILS_CACHE)
      @store = store
    end

    def exist?(key)
      @store.exist?(key)
    end

    def open(key)
      @store.read(key)
    end

    def read(key)
      body = open(key)
      body.join if body
    end

    def write(body)
      buf = []
      key, size = slurp(body) { |part| buf << part }
      @store.write(key, buf)
      [key, size]
    end

    ::Rack::Cache::EntityStore::RAILS = self
  end
end
