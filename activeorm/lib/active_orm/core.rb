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
        proxy &&= proxy_registry[proxy]
        if proxy.nil?
          obj
        else
          proxy.new(obj)
        end
      end

      def use(options)
        case options[:orm].to_s
        when /test[_\W\s]?orm/i
          options.reverse_merge!( :for => ActiveORM::TestORMModel, :proxy => Proxies::TestORMProxy )
        when /sequel/i
          options.reverse_merge!( :for => Sequel::Model, :proxy => Proxies::SequelProxy )
        when /active[_\W\s]?record/i
          options.reverse_merge!( :for => ActiveRecord::Base, :proxy => nil )
        when /data[_\W\s]?mapper/i
          options.reverse_merge!( :for => DataMapper::Resource, :proxy => nil )
        end
        ActiveORM.register options[:for], options[:proxy]
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