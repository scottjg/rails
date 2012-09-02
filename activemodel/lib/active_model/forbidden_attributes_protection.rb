module ActiveModel
  class ForbiddenAttributesError < StandardError
  end

  module ForbiddenAttributesProtection
    extend ActiveSupport::Concern

    module ClassMethods
      def attributes_forbidden_by_default
        []
      end
    end

    def sanitize_for_mass_assignment(attributes, options = {})
      attributes.reject! do |key, value|
        self.class.attributes_forbidden_by_default.include?(key)
      end

      if attributes.respond_to?(:permitted?) && !attributes.permitted?
        raise ActiveModel::ForbiddenAttributesError
      else
        attributes
      end
    end
  end
end
