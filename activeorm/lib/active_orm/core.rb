module ActiveOrm
  class ActiveOrmError < StandardError; end
  class ProxyNotFoundException < ActiveOrmError; end
  class AbstractProxyMethod < ActiveOrmError; end

  module Core
    module ClassMethods
      def proxyable? obj
        !find_key(obj).empty?
      end

      def proxy obj
        @_proxy_cache ||= {}
        puts find_key(obj).inspect
        @_proxy_registry[find_key(obj)].new(obj)
      end

      def register obj_class, obj_proxy_class
        @_proxy_registry ||= {}
        @_proxy_registry[obj_class.to_s] = obj_proxy_class
      end
      
      def load
        # Rails::Initializer.after_app_loads
      end
      
      protected
        def find_key(obj)
          @_proxy_key_cache ||= {}
          @_proxy_key_cache[obj.class.to_s] ||= obj.class.ancestors.find{|a| @_proxy_registry[a.to_s] }.to_s || obj.class.included_modules.find{|a| @_proxy_registry[a].to_s }.to_s
        end
    end
  end
end