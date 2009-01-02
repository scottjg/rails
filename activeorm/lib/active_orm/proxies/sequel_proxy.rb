module ActiveOrm
  module Proxies
    class SequelProxy < AbstractProxy
      def new?
        model.new?
      end
    end
  end
end