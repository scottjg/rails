require 'active_support/core_ext/array/wrap'

module ActiveResource
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :before_validation, :after_validation, :before_save, :around_save, :after_save,
      :before_create, :around_create, :after_create, :before_update, :around_update,
      :after_update, :before_destroy, :around_destroy, :after_destroy
    ]


    included do
      extend ActiveModel::Callbacks
      include ActiveModel::Validations::Callbacks
      ActiveResource::Validations.send(:include, ActiveResource::Validations::Callbacks)

      define_model_callbacks :save, :create, :update, :destroy
    end

    module InstanceMethods
      def save
        run_callbacks(:save) { super }
      end

      def destroy
        run_callbacks(:destroy) { super }
      end

      protected
      def update
        run_callbacks(:update) { super }
      end

      def create
        run_callbacks(:create) { super }
      end
    end
  end

  module Validations
    module Callbacks
      def valid?
        run_callbacks(:validation) { super }
      end
    end
  end
end
