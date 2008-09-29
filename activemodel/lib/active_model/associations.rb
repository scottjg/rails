require 'active_model/associations/association_proxy'

require 'active_model/associations/association_collection'

require 'active_model/associations/has_many_association'

module ActiveModel
  # See AcitveModel::Associations::ClassMethods for documentation.
  module Associations # :nodoc:
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Clears out the association cache
    def clear_association_cache #:nodoc:
      self.class.reflect_on_all_associations.to_a.each do |assoc|
        instance_variable_set "@#{assoc.name}", nil
      end unless self.new_record?
    end  

    module ClassMethods    
      def has_many(association_id, options = {}, &extension)
        reflection = create_has_many_reflection(association_id, options, &extension)

        configure_dependency_for_has_many(reflection)
        add_multiple_associated_validation_callbacks(reflection.name) unless options[:validate] == false
        add_multiple_associated_save_callbacks(reflection.name)
        add_association_callbacks(reflection.name, reflection.options)
        if options[:through]
          collection_accessor_methods(reflection, HasManyThroughAssociation)
        else
          collection_accessor_methods(reflection, HasManyAssociation)
        end
      end
      
      private
      mattr_accessor :valid_keys_for_has_many_association
      @@valid_keys_for_has_many_association = [
        :class_name, :table_name, :foreign_key, :primary_key,
        :dependent,
        :select, :conditions, :include, :order, :group, :limit, :offset,
        :as, :through, :source, :source_type,
        :uniq,
        :finder_sql, :counter_sql,
        :before_add, :after_add, :before_remove, :after_remove,
        :extend, :readonly,
        :validate
      ]

      def create_has_many_reflection(association_id, options, &extension)
        options.assert_valid_keys(valid_keys_for_has_many_association)
        options[:extend] = create_extension_modules(association_id, extension, options[:extend])

        create_reflection(:has_many, association_id, options, self)
      end
      
      def create_extension_modules(association_id, block_extension, extensions)
        if block_extension
          extension_module_name = "#{self.to_s.demodulize}#{association_id.to_s.camelize}AssociationExtension"

          silence_warnings do
            self.parent.const_set(extension_module_name, Module.new(&block_extension))
          end
          Array(extensions).push("#{self.parent}::#{extension_module_name}".constantize)
        else
          Array(extensions)
        end        
      end
      
      # See HasManyAssociation#delete_records.  Dependent associations
      # delete children, otherwise foreign key is set to NULL.
      def configure_dependency_for_has_many(reflection)
        if reflection.options.include?(:dependent)
          warn("Currently unsupported in ActiveModel")
        end
      end
      
      def add_multiple_associated_validation_callbacks(association_name)
        method_name = "validate_associated_records_for_#{association_name}".to_sym
        ivar = "@#{association_name}"

        define_method(method_name) do
          association = instance_variable_get(ivar) if instance_variable_defined?(ivar)

          if association.respond_to?(:loaded?)
            if new_record?
              association
            elsif association.loaded?
              association.select { |record| record.new_record? }
            else
              association.target.select { |record| record.new_record? }
            end.each do |record|
              errors.add association_name unless record.valid?
            end
          end
        end

        validate method_name
      end
      
      def add_multiple_associated_save_callbacks(association_name)
        ivar = "@#{association_name}"

        method_name = "before_save_associated_records_for_#{association_name}".to_sym
        define_method(method_name) do
          @new_record_before_save = new_record?
          true
        end
        before_save method_name

        method_name = "after_create_or_update_associated_records_for_#{association_name}".to_sym
        define_method(method_name) do
          association = instance_variable_get(ivar) if instance_variable_defined?(ivar)

          records_to_save = if @new_record_before_save
            association
          elsif association.respond_to?(:loaded?) && association.loaded?
            association.select { |record| record.new_record? }
          elsif association.respond_to?(:loaded?) && !association.loaded?
            association.target.select { |record| record.new_record? }
          else
            []
          end
          records_to_save.each { |record| association.send(:insert_record, record) } unless records_to_save.blank?

          # reconstruct the SQL queries now that we know the owner's id
          # association.send(:construct_) if association.respond_to?(:construct_sql)
          warn("FIXME: what to do to avoid SQL-specific code here but still support the functionality needed?")
        end

        # Doesn't use after_save as that would save associations added in after_create/after_update twice
        after_create method_name
        after_update method_name
      end
      
      def add_association_callbacks(association_name, options)
        callbacks = %w(before_add after_add before_remove after_remove)
        callbacks.each do |callback_name|
          full_callback_name = "#{callback_name}_for_#{association_name}"
          defined_callbacks = options[callback_name.to_sym]
          if options.has_key?(callback_name.to_sym)
            class_inheritable_reader full_callback_name.to_sym
            write_inheritable_attribute(full_callback_name.to_sym, [defined_callbacks].flatten)
          else
            write_inheritable_attribute(full_callback_name.to_sym, [])
          end
        end
      end
      
      def collection_reader_method(reflection, association_proxy_class)
        define_method(reflection.name) do |*params|
          ivar = "@#{reflection.name}"

          force_reload = params.first unless params.empty?
          association = instance_variable_get(ivar) if instance_variable_defined?(ivar)

          unless association.respond_to?(:loaded?)
            association = association_proxy_class.new(self, reflection)
            instance_variable_set(ivar, association)
          end

          association.reload if force_reload

          association
        end
      end

      def collection_accessor_methods(reflection, association_proxy_class, writer = true)
        collection_reader_method(reflection, association_proxy_class)

        if writer
          define_method("#{reflection.name}=") do |new_value|
            # Loads proxy class instance (defined in collection_reader_method) if not already loaded
            association = send(reflection.name)
            association.replace(new_value)
            association
          end

          define_method("#{reflection.name.to_s.singularize}_ids=") do |new_value|
            ids = (new_value || []).reject { |nid| nid.blank? }
            send("#{reflection.name}=", reflection.class_name.constantize.find(ids))
          end
        end
      end      
    end
  end
end