module ActiveOrm
  module Proxies
    class AbstractProxy
      attr :model
  
      def initialize(obj)
        @model = obj
      end
  
      def new?
        raise AbstractProxyMethod
      end
  
      def errors
        raise AbstractProxyMethod
      end
  
      def valid?
        raise AbstractProxyMethod
      end
    end
  end
end