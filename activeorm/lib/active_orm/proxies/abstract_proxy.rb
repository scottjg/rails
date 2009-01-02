module ActiveOrm
  module Proxies
    class AbstractProxy
      attr :model
  
      def initialize(obj)
        @model = obj
      end
  
      def new?
        model.new_record?
      end
  
      def errors
        model.errors
      end
  
      def valid?
        model.valid?
      end
    end
  end
end