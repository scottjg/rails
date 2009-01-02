module ActiveOrm
  class ActiveOrmError < StandardError; end
  class ProxyNotFoundException < ActiveOrmError; end
  class AbstractProxyMethod < ActiveOrmError; end

  module Core
    class << self
      def proxyable? obj
        obj.class.ancestors.find{|a| @_proxy_registry.key? a } || obj.class.included_modules.find{|a| @_proxy_registry.key? a }
      end

      def proxy obj
        raise ProxyNotFoundException unless proxyable? obj
        @_proxy_cache ||= {}
        @_proxy_cache[obj] ||= @_proxy_registry[obj.class].new(obj)
      end

      def register obj_class, obj_proxy_class
        @_proxy_registry ||= {}
        @_proxy_registry[obj_class] = obj_proxy_class
      end
    end
  end
end