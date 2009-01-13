module ActiveORM
  module Proxies
    class TestORMProxy < AbstractProxy
      def new_record?
        model.new_record?
      end
  
      def valid?
        model.valid?
      end
    end
  end
end