module ActiveOrm
  module Proxies
    class SequelProxy
      def new?
        model.new?
      end

      def valid?
        model.valid?
      end
    end
  end
end