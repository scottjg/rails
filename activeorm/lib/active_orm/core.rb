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
        @_proxy_registry[find_key(obj)].new(obj)
      end

      def register obj_class, obj_proxy_class
        @_proxy_registry ||= {}
        @_proxy_registry[obj_class] = obj_proxy_class
      end
      
      # TODO: This is not a permanant method. Will be replaced with something
      # more flexible at a later date pending the bootloader changes.
      def use(orm)
        case orm
        when /test[_\W\s]orm/i
          ActiveOrm.register ActiveOrm::TestOrmModel, ActiveOrm::Proxies::TestOrmProxy
        when /sequel/i
          ActiveOrm.register Sequel::Model, ActiveOrm::Proxies::SequelProxy
        when /active[_\W\s]record/i
          ActiveOrm.register ActiveRecord::Base, ActiveOrm::Proxies::ActiveRecordProxy
        when /data[_\W\s]mapper/i
          ActiveOrm.register DataMapper::Resource, ActiveOrm::Proxies::DataMapperProxy
        else
          raise ProxyNotFoundException
        end
      end
      
      protected
        def find_key(obj)
          @_proxy_key_cache ||= {}
          @_proxy_key_cache[obj.class] ||= obj.class.ancestors.find{|a| @_proxy_registry[a] } || obj.class.included_modules.find{|a| @_proxy_registry[a] }
        end
    end
  end
end