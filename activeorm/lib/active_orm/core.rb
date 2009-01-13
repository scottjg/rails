module ActiveORM
  class ActiveORMError < StandardError; end
  class ProxyNotFoundException < ActiveORMError; end
  class AbstractProxyMethod < ActiveORMError; end

  module Core
    module ClassMethods
      def supports?(obj)
        find_key(obj) || obj.respond_to?(:new_record?)
      end

      def for(obj)
        proxy = find_key(obj)
        if proxy.nil? || [proxy, proxy_registry[proxy]].include?(:none)
          obj
        else
          proxy_registry[proxy].new(obj)
        end
      end

      def use(options)
        case options[:orm].to_s
        when /test[_\W\s]?orm/i
          options.reverse_merge!( :klass => ActiveORM::TestORMModel, :proxy => Proxies::TestORMProxy )
        when /sequel/i
          options.reverse_merge!( :klass => Sequel::Model, :proxy => Proxies::SequelProxy )
        when /active[_\W\s]?record/i
          options.reverse_merge!( :klass => ActiveRecord::Base, :proxy => :none )
        when /data[_\W\s]?mapper/i
          options.reverse_merge!( :klass => DataMapper::Resource, :proxy => :none )
        end
        ActiveORM.register options[:klass], options[:proxy]
      end
      
      protected
        def proxy_registry
          @_proxy_registry ||= {}
        end
        
        def proxy_key_cache
          @_proxy_key_cache ||= {}
        end
      
        def register(obj_class, obj_proxy_class)
          proxy_registry[obj_class] = obj_proxy_class
        end
        
        def find_key(obj)
          proxy_key_cache[obj.class] ||= proxy_registry.keys.find {|k, v| obj.is_a? k }
        end
    end
  end
end