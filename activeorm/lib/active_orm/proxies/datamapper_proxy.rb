module ActiveOrm
  module Proxies
    class DataMapperProxy  < AbstractProxy
      def new?
        model.new_record?
      end
      
      def valid?
        model.valid?
      end
    end
  end
end