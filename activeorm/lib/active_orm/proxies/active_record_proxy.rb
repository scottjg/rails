module ActiveOrm
  module Proxies
    class DataMapperProxy  < AbstractProxy
      def new?
        model.new_record?
      end
    end
  end
end