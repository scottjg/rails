module ActiveOrm
  module Proxies
    class DataMapperProxy  < AbstractProxy
      def errors
        model.errors
      end
    end
  end
end