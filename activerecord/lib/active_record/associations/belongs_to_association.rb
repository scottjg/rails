module ActiveRecord
  # = Active Record Belongs To Associations
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:
      def replace(record)
        raise_on_type_mismatch(record) if record

        replace_keys(record)
        set_inverse_instance(record)

        @updated = true if record

        self.target = record
      end

      def updated?
        @updated
      end

      private

        def replace_keys(record)
          owner[reflection.foreign_key] = record && record[reflection.association_primary_key]
        end

        # NOTE - for now, we're only supporting inverse setting from belongs_to back onto
        # has_one associations.
        def invertible_for?(record)
          inverse = inverse_reflection_for(record)
          inverse && inverse.macro == :has_one
        end

        def stale_state
          owner[reflection.foreign_key].to_s
        end
    end
  end
end
