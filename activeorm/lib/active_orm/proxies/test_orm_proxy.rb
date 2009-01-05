module ActiveORM
  module Proxies
    class TestORMProxy < AbstractProxy
      def new?
        model.new_record?
      end
  
      def valid?
        model.valid?
      end
    end
  end
end