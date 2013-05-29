
module ActionMailer
  module DeprecatedDeliveryMethods
    extend ActiveSupport::Concern

    module ClassMethods

      def add_delivery_method(symbol, klass, default_options={})
        super

        return if respond_to?(:"#{symbol}_settings")

        deprecation_warning = "ActionMailer configuration through xxx_settings is deprecated. Use ActionMailer::Base.configuration instead."

        define_singleton_method :"#{symbol}_settings" do
          ActiveSupport::Deprecation.warn deprecation_warning
          delivery_method_options[symbol.to_sym]
        end

        define_singleton_method :"#{symbol}_settings=" do |settings|
          ActiveSupport::Deprecation.warn deprecation_warning
          self.delivery_method_options = delivery_method_options.merge(symbol.to_sym => settings)
        end

      end
    end

  end
end
