module ActiveOrm
  module Proxies
    class SequelProxy < AbstractProxy
      def new_record?
        model.new?
      end
    end
  end
end