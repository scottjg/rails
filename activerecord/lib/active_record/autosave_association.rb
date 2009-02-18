module ActiveRecord
  # AutosaveAssociation is a module that takes care of automatically saving
  # your associations when the parent is saved. In addition to saving, it
  # also destroys any associations that were marked for destruction.
  # (See mark_for_destruction and marked_for_destruction?)
  #
  # Saving of the parent, its associations, and the destruction of marked
  # associations, all happen inside 1 transaction. This should never leave the
  # database in an inconsistent state after, for instance, mass assigning
  # attributes and saving them.
  #
  # If validations for any of the associations fail, their error messages will
  # be applied to the parent.
  #
  # Note that it also means that associations marked for destruction won't
  # be destroyed directly. They will however still be marked for destruction.
  #
  # === One-to-one Example
  #
  # Consider a Post model with one Author:
  #
  #   class Post
  #     has_one :author, :autosave => true
  #   end
  #
  # Saving changes to the parent and its associated model can now be performed
  # automatically _and_ atomically:
  #
  #   post = Post.find(1)
  #   post.title # => "The current global position of migrating ducks"
  #   post.author.name # => "alloy"
  #
  #   post.title = "On the migration of ducks"
  #   post.author.name = "Eloy Duran"
  #
  #   post.save
  #   post.reload
  #   post.title # => "On the migration of ducks"
  #   post.author.name # => "Eloy Duran"
  #
  # Destroying an associated model, as part of the parent's save action, is as
  # simple as marking it for destruction:
  #
  #   post.author.mark_for_destruction
  #   post.author.marked_for_destruction? # => true
  #
  # Note that the model is _not_ yet removed from the database:
  #   id = post.author.id
  #   Author.find_by_id(id).nil? # => false
  #
  #   post.save
  #   post.reload.author # => nil
  #
  # Now it _is_ removed from the database:
  #   Author.find_by_id(id).nil? # => true
  #
  # === One-to-many Example
  #
  # Consider a Post model with many Comments:
  #
  #   class Post
  #     has_many :comments, :autosave => true
  #   end
  #
  # Saving changes to the parent and its associated model can now be performed
  # automatically _and_ atomically:
  #
  #   post = Post.find(1)
  #   post.title # => "The current global position of migrating ducks"
  #   post.comments.first.body # => "Wow, awesome info thanks!"
  #   post.comments.last.body # => "Actually, your article should be named differently."
  #
  #   post.title = "On the migration of ducks"
  #   post.comments.last.body = "Actually, your article should be named differently. [UPDATED]: You are right, thanks."
  #
  #   post.save
  #   post.reload
  #   post.title # => "On the migration of ducks"
  #   post.comments.last.body # => "Actually, your article should be named differently. [UPDATED]: You are right, thanks."
  #
  # Destroying one of the associated models members, as part of the parent's
  # save action, is as simple as marking it for destruction:
  #
  #   post.comments.last.mark_for_destruction
  #   post.comments.last.marked_for_destruction? # => true
  #   post.comments.length # => 2
  #
  # Note that the model is _not_ yet removed from the database:
  #   id = post.comments.last.id
  #   Comment.find_by_id(id).nil? # => false
  #
  #   post.save
  #   post.reload.comments.length # => 1
  #
  # Now it _is_ removed from the database:
  #   Comment.find_by_id(id).nil? # => true
  #
  # === Validation
  #
  # Validation is performed on the parent as usual, but also on all autosave
  # enabled associations. If any of the associations fail validation, its
  # error messages will be applied on the parents errors object and validation
  # of the parent will fail.
  #
  # Consider a Post model with Author which validates the presence of its name
  # attribute:
  #
  #   class Post
  #     has_one :author, :autosave => true
  #   end
  #
  #   class Author
  #     validates_presence_of :name
  #   end
  #
  #   post = Post.find(1)
  #   post.author.name = ''
  #   post.save # => false
  #   post.errors # => #<ActiveRecord::Errors:0x174498c @errors={"author_name"=>["can't be blank"]}, @base=#<Post ...>>
  #
  # No validations will be performed on the associated models when validations
  # are skipped for the parent:
  #
  #   post = Post.find(1)
  #   post.author.name = ''
  #   post.save(false) # => true
  module AutosaveAssociation
    def self.included(base)
      base.class_eval do
        base.extend(ClassMethods)

        alias_method_chain :reload, :autosave_associations

        %w{ has_one belongs_to has_many has_and_belongs_to_many }.each do |type|
          base.send("valid_keys_for_#{type}_association") << :autosave
        end
      end
    end

    module ClassMethods
      # Returns whether or not the parent, <tt>self</tt>, and any loaded autosave associations are valid.

      def add_single_associated_validation_callbacks(reflection)
        # TODO: move to the enable_autosave_on_one_to_one_association
        add_single_associated_save_callbacks(reflection) if reflection.options[:autosave]

        method_name = "validate_associated_records_for_#{reflection.name}"
        define_method(method_name) do
          if (association = association_instance_get(reflection.name)) && !association.target.nil?
            autosave_association_valid?(reflection, association)
          end
        end

        validate method_name
      end

      def add_multiple_associated_validation_callbacks(reflection)
        method_name = "validate_associated_records_for_#{reflection.name}"
        define_method(method_name) do
          autosave = reflection.options[:autosave]
          if association = association_instance_get(reflection.name)
            if new_record?
              association
            elsif association.loaded?
              autosave ? association : association.select { |record| record.new_record? }
            else
              autosave ? (association.target || []) : association.target.select { |record| record.new_record? }
            end.each do |record|
              autosave_association_valid?(reflection, record)
            end
          end
        end

        validate method_name
      end

      # Saves the parent, <tt>self</tt>, and any loaded autosave associations.
      # In addition, it destroys all children that were marked for destruction
      # with mark_for_destruction.
      #
      # This all happens inside a transaction, _if_ the Transactions module is included into
      # ActiveRecord::Base after the AutosaveAssociation module, which it does by default.

      # TODO: Merge inline autosave code from Associations has_one & belongs_to
      def add_single_associated_save_callbacks(reflection)
        method_name = "after_create_or_update_associated_records_for_#{reflection.name}"
        define_method(method_name) do
          if (association = association_instance_get(reflection.name)) && !association.target.nil?
            association.marked_for_destruction? ? association.destroy : association.save(false)
          end
        end

        # Doesn't use after_save as that would save associations added in after_create/after_update twice
        after_create method_name
        after_update method_name
      end

      def add_has_one_associated_save_callbacks(reflection)
        method_name = "has_one_after_save_for_#{reflection.name}"
        define_method(method_name) do
          association = association_instance_get(reflection.name)
          if association && (new_record? || association.new_record? || association[reflection.primary_key_name] != id)
            association[reflection.primary_key_name] = id
            association.save(true)
          end
        end
        after_save method_name
      end

      def add_belongs_to_associated_save_callbacks(reflection)
        if reflection.options[:polymorphic]
          # FIXME: NO TESTS FAIL WHEN DISABLING THIS CODE!
          method_name = "polymorphic_belongs_to_before_save_for_#{reflection.name}"
          define_method(method_name) do
            association = association_instance_get(reflection.name)
            if association && association.target
              if association.new_record?
                association.save(true)
              end

              if association.updated?
                self[reflection.primary_key_name] = association.id
                # This seems to be the only difference.
                self[reflection.options[:foreign_type]] = association.class.base_class.name.to_s
              end
            end
          end
          before_save method_name
        else
          method_name = "belongs_to_before_save_for_#{reflection.name}"
          define_method(method_name) do
            if association = association_instance_get(reflection.name)
              if association.new_record?
                association.save(true)
              end
          
              if association.updated?
                self[reflection.primary_key_name] = association.id
              end
            end
          end
          before_save method_name
        end
      end

      def add_multiple_associated_save_callbacks(reflection)
        association_name = reflection.name

        method_name = "before_save_associated_records_for_#{association_name}"
        define_method(method_name) do
          @new_record_before_save = new_record?
          true
        end
        before_save method_name

        method_name = "after_create_or_update_associated_records_for_#{association_name}"
        define_method(method_name) do
          association = association_instance_get(association_name)
          autosave = reflection.options[:autosave]

          records_to_save = if @new_record_before_save
            association
          elsif association && association.loaded?
            autosave ? association : association.select { |record| record.new_record? }
          elsif association && !association.loaded?
            autosave ? (association.target || []) : association.target.select { |record| record.new_record? }
          else
            []
          end

          unless records_to_save.blank?
            records_to_save.each do |record|
              if autosave && record.marked_for_destruction?
                record.destroy
              else
                if @new_record_before_save || record.new_record?
                  association.send(:insert_record, record)
                else
                  record.save(false)
                end
              end
            end
          end

          # reconstruct the SQL queries now that we know the owner's id
          association.send(:construct_sql) if association.respond_to?(:construct_sql)
        end

        # Doesn't use after_save as that would save associations added in after_create/after_update twice
        after_create method_name
        after_update method_name
      end
    end

    # Returns whether or not the association is valid and applies any errors to the parent, <tt>self</tt>, if it wasn't.
    def autosave_association_valid?(reflection, association)
      unless (parent_valid = association.valid?)
        if reflection.options[:autosave]
          association.errors.each do |attribute, message|
            attribute = "#{reflection.name}_#{attribute}"
            errors.add(attribute, message) unless errors.on(attribute)
          end
        else
          errors.add(reflection.name)
        end
      end
      parent_valid
    end

    # Reloads the attributes of the object as usual and removes a mark for destruction.
    def reload_with_autosave_associations(options = nil)
      @marked_for_destruction = false
      reload_without_autosave_associations(options)
    end

    # Marks this record to be destroyed as part of the parents save transaction.
    # This does _not_ actually destroy the record yet, rather it will be destroyed when <tt>parent.save</tt> is called.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for this associated model.
    def mark_for_destruction
      @marked_for_destruction = true
    end

    # Returns whether or not this record will be destroyed as part of the parents save transaction.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for this associated model.
    def marked_for_destruction?
      @marked_for_destruction
    end
  end
end