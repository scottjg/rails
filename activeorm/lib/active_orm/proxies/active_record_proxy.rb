module ActiveOrm
  module Proxies
    class ActiveRecordProxy  < AbstractProxy
      def new?
        model.new_record?
      end
      
      def valid?
        model.valid?
      end
    end
  end
end