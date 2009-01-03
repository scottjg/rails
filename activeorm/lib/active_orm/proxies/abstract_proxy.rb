module ActiveOrm
  module Proxies
    class AbstractProxy
      attr :model
  
      def initialize(obj)
        @model = obj
      end
  
      def new_record?
        model.new_record?
      end
  
      def errors
        raise AbstractProxyMethod
      end
  
      def valid?
        model.valid?
      end
    end
  end
end