module ActiveRecord
  module Associations
    module InverseAssociations
      
      module AssociationProxyMethods
        
      end

      module AssociationCollectionMethods
      end

      module BelongsToAssociationMethods
        def self.included(base)
          base.class_eval do
            def create_with_self_control(attributes = {})
              record = create_without_self_control(attributes)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :create, :self_control

            def build_with_self_control(attributes = {})
              record = build_without_self_control(attributes)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :build, :self_control

            def find_target_with_self_control
              record = find_target_without_self_control
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :find_target, :self_control
          end
        end
      end

      module HasOneAssociationMethods
        def self.included(base)
          base.class_eval do
            def create_with_self_control(attributes = {}, replace_existing = true)
              record = create_without_self_control(attributes, replace_existing)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :create, :self_control

            def create_with_self_control(attributes = {}, replace_existing = true)
              record = create_without_self_control(attributes, replace_existing)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :create, :self_control


            def build_with_self_control(attributes = {}, replace_existing = true)
              record = build_without_self_control(attributes, replace_existing)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :build, :self_control

            def find_target_with_self_control
              record = find_target_without_self_control
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :find_target, :self_control
          end
        end
      end

      module HasManyAssociationMethods
        def self.included(base)
          base.class_eval do
            def create_with_self_control(attributes = {})
              record = create_without_self_control(attributes)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :create, :self_control

            def build_with_self_control(attributes = {})
              record = build_without_self_control(attributes)
              set_inverse_instance(record, @owner)
              record
            end
            alias_method_chain :build, :self_control

            def find_target_with_self_control
              records = find_target_without_self_control
              records.each do |record|
                set_inverse_instance(record, @owner)
              end
              records
            end
            alias_method_chain :find_target, :self_control
          end
        end
      end

      # Not yet... :(

      module BelongsToPolymorphicAssociationMethods
      end

      module HasAndBelongsToManyAssociationMethods
      end

      module HasManyThroughAssociationMethods
      end

      module HasOneThroughAssociationMethods
      end
    end
  end
end
