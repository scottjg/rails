module ActiveOrm
  class ActiveOrmError < StandardError; end
  class ProxyNotFoundException < ActiveOrmError; end
  class AbstractProxyMethod < ActiveOrmError; end

  module Core
    module ClassMethods
      def proxyable? obj
        find_key(obj)
      end

      def proxy obj
        @_proxy_cache ||= {}
        @_proxy_cache[obj.object_id] ||= @_proxy_registry[find_key(obj)].new(obj)
      end

      def register obj_class, obj_proxy_class
        @_proxy_registry ||= {}
        @_proxy_registry[obj_class] = obj_proxy_class
      end
      
      protected
        def find_key(obj)
          obj.class.ancestors.find{|a| @_proxy_registry[a] } || obj.class.included_modules.find{|a| @_proxy_registry[a] }
        end
    end
  end
end