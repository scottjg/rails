module ActiveRecord
  # AutosaveAssociation is a module that takes care of automatically saving
  # your associations when the parent is saved. In addition to saving, it
  # also removes any associations that were marked for removal.
  # (See mark_for_removal! and marked_for_removal?)
  #
  # Saving of the parent, its associations, and the removal of marked
  # associations, all happen inside 1 transaction. This should never leave the
  # database in an inconsistent state after, for instance, mass assigning
  # attributes and saving them.
  #
  # If validations for any of the associations fail, their error messages will
  # be applied to the parent.
  #
  # Note that it also means that associations marked for removal won't be
  # removed directly. They will however still be marked for removal.
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
  # Removing an associated model, as part of the parent's save action, is as
  # simple as marking it for removal:
  #
  #   post.author.mark_for_removal!
  #   post.author.marked_for_removal? # => true
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
  # Removing the record is done with #destroy by default, but other options are
  # available. See #mark_for_removal! for more info.
  #
  # === One-to-many Example
  #
  # Consider a Post model with many Comments:
  #
  #   class Post
  #     has_many :comments, :autosave => true
  #   end
  #
  # Saving changes to the parent and its associated members can now be
  # performed automatically _and_ atomically:
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
  # Removing one of the associated members, as part of the parent's save
  # action, is as simple as marking it for removal:
  #
  #   post.comments.last.mark_for_removal!
  #   post.comments.last.marked_for_removal? # => true
  #   post.comments.length # => 2
  #
  # Note that the model is _not_ yet removed from the database:
  #
  #   id = post.comments.last.id
  #   Comment.find_by_id(id).nil? # => false
  #
  #   post.save
  #   post.reload.comments.length # => 1
  #
  # Now it _is_ removed from the database:
  #   Comment.find_by_id(id).nil? # => true
  #
  # Removing the member is done with #destroy by default, but other options are
  # available. See #mark_for_removal! for more info.
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
  #   post.errors # => #<ActiveRecord::Errors:0x174498c @errors={"Author.name"=>["can't be blank"]}, @base=#<Post ...>>
  #
  # No validations will be performed on the associated models when validations
  # are skipped for the parent:
  #
  #   post = Post.find(1)
  #   post.author.name = ''
  #   post.save(false) # => true
  module AutosaveAssociation
    extend ActiveSupport::Concern

    ASSOCIATION_TYPES = %w{ has_one belongs_to has_many has_and_belongs_to_many }

    included do
      alias_method_chain :reload, :autosave_associations

      ASSOCIATION_TYPES.each do |type|
        send("valid_keys_for_#{type}_association") << :autosave
      end
    end

    module ClassMethods
      private

      # def belongs_to(name, options = {})
      #   super
      #   add_autosave_association_callbacks(reflect_on_association(name))
      # end
      ASSOCIATION_TYPES.each do |type|
        module_eval %{
          def #{type}(name, options = {})
            super
            add_autosave_association_callbacks(reflect_on_association(name))
          end
        }
      end

      # Adds a validate and save callback for the association as specified by
      # the +reflection+.
      #
      # For performance reasons, we don't check whether to validate at runtime,
      # but instead only define the method and callback when needed. However,
      # this can change, for instance, when using nested attributes, which is
      # called _after_ the association has been defined. Since we don't want
      # the callbacks to get defined multiple times, there are guards that
      # check if the save or validation methods have already been defined
      # before actually defining them.
      def add_autosave_association_callbacks(reflection)
        save_method = :"autosave_associated_records_for_#{reflection.name}"
        validation_method = :"validate_associated_records_for_#{reflection.name}"
        collection = reflection.collection_association?

        unless method_defined?(save_method)
          if collection
            before_save :before_save_collection_association

            define_method(save_method) { save_collection_association(reflection) }
            # Doesn't use after_save as that would save associations added in after_create/after_update twice
            after_create save_method
            after_update save_method
          else
            if reflection.macro == :has_one
              define_method(save_method) { save_has_one_association(reflection) }
              after_save save_method
            else
              define_method(save_method) { save_belongs_to_association(reflection) }
              before_save save_method
            end
          end
        end

        if reflection.validate? && !method_defined?(validation_method)
          method = (collection ? :validate_collection_association : :validate_single_association)
          define_method(validation_method) { send(method, reflection) }
          validate validation_method
        end
      end
    end

    # Reloads the attributes of the object as usual and removes a mark for destruction.
    def reload_with_autosave_associations(options = nil)
      @mark_for_removal_type = nil
      reload_without_autosave_associations(options)
    end

    # Returns the type of removal that will be applied to this record when
    # <tt>parent.save</tt> is called. See #mark_for_removal! for more info.
    attr_reader :mark_for_removal_type

    # Marks this record to be removed as part of the parents save transaction.
    # This does _not_ actually remove the record yet, rather it will be removed
    # when <tt>parent.save</tt> is called.
    #
    # The way the record will be removed is specified by +type+, which should
    # be one of: <tt>:destroy</tt>, <tt>:delete</tt>, or <tt>:nullify</tt>.
    # Defaults to <tt>:destroy</tt>.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for
    # this associated model.
    def mark_for_removal!(type = :destroy)
      unless valid_mark_for_removal_types.include?(type)
        raise ArgumentError, "The type `#{type.inspect}' given to #mark_for_removal! isn't supported. Should be one of :destroy, :delete, or :nullify."
      end
      @mark_for_removal_type = type
    end

    # Returns whether or not this record will be removed as part of the parents
    # save transaction.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for
    # this associated model.
    def marked_for_removal?
      !@mark_for_removal_type.nil?
    end

    # Returns whether or not this record will be removed as part of the parents
    # save transaction.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for
    # this associated model.
    #
    # Note that this alias of #marked_for_removal? exists mainly to use from a
    # form builder.
    #
    # TODO: Move to nested attributes.
    alias_method :mark_for_removal, :marked_for_removal?

    # Marks this record to be destroyed as part of the parents save
    # transaction. This does _not_ actually destroy the record yet, rather it
    # will be destroyed when <tt>parent.save</tt> is called.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for
    # this associated model.
    #
    # Deprecated: Use #mark_for_removal! instead.
    def mark_for_destruction
      ActiveSupport::Deprecation.warn "#mark_for_destruction is deprecated in autosave association. Use #mark_for_removal! instead."
      mark_for_removal!
    end

    # Returns whether or not this record will be destroyed as part of the
    # parents save transaction.
    #
    # Only useful if the <tt>:autosave</tt> option on the parent is enabled for
    # this associated model.
    #
    # Deprecated: Use #marked_for_removal? instead.
    def marked_for_destruction?
      ActiveSupport::Deprecation.warn "#marked_for_destruction? is deprecated in autosave association. Use #marked_for_removal? instead."
      marked_for_removal?
    end

    private

    mattr_accessor :valid_mark_for_removal_types
    @@valid_mark_for_removal_types = [:destroy, :delete, :nullify]

    # Returns the record for an association collection that should be validated
    # or saved. If +autosave+ is +false+ only new records will be returned,
    # unless the parent is/was a new record itself.
    def associated_records_to_validate_or_save(association, new_record, autosave)
      if new_record
        association
      elsif association.loaded?
        autosave ? association : association.find_all { |record| record.new_record? }
      else
        autosave ? association.target : association.target.find_all { |record| record.new_record? }
      end
    end

    # Validate the association if <tt>:validate</tt> or <tt>:autosave</tt> is
    # turned on for the association specified by +reflection+.
    def validate_single_association(reflection)
      if (association = association_instance_get(reflection.name)) && !association.target.nil?
        association_valid?(reflection, association)
      end
    end

    # Validate the associated records if <tt>:validate</tt> or
    # <tt>:autosave</tt> is turned on for the association specified by
    # +reflection+.
    def validate_collection_association(reflection)
      if association = association_instance_get(reflection.name)
        if records = associated_records_to_validate_or_save(association, new_record?, reflection.options[:autosave])
          records.each { |record| association_valid?(reflection, record) }
        end
      end
    end

    # Returns whether or not the association is valid and applies any errors to
    # the parent, <tt>self</tt>, if it wasn't. Skips any <tt>:autosave</tt>
    # enabled records if they're marked_for_destruction? or destroyed.
    def association_valid?(reflection, association)
      return true if association.destroyed? || association.marked_for_removal?

      unless valid = association.valid?
        if reflection.options[:autosave]
          association.errors.each do |attribute, message|
            attribute = "#{reflection.name}.#{attribute}"
            errors[attribute] << message if errors[attribute].empty?
          end
        else
          errors.add(reflection.name)
        end
      end
      valid
    end

    # Remove the +record+ as specified in <tt>record.mark_for_removal_type</tt>
    #
    # Removes the +record+ from +from_collection+ if the association is a
    # collection.
    def remove_marked_for_removal_record(record, reflection, from_collection = nil)
      if record.mark_for_removal_type == :nullify
        if from_collection
          from_collection.send(:nullify_records, [record])
        elsif reflection.belongs_to?
          write_attribute(reflection.primary_key_name, nil)
        else
          record.update_attribute(reflection.primary_key_name, nil)
        end
      else
        if from_collection
          from_collection.send(record.mark_for_removal_type, record)
        else
          record.send(record.mark_for_removal_type)
        end
      end
    end

    # Is used as a before_save callback to check while saving a collection
    # association whether or not the parent was a new record before saving.
    def before_save_collection_association
      @new_record_before_save = new_record?
      true
    end

    # Saves any new associated records, or all loaded autosave associations if
    # <tt>:autosave</tt> is enabled on the association.
    #
    # In addition, it destroys all children that were marked for destruction
    # with mark_for_destruction.
    #
    # This all happens inside a transaction, _if_ the Transactions module is
    # included into ActiveRecord::Base after the AutosaveAssociation module,
    # which it does by default.
    def save_collection_association(reflection)
      if association = association_instance_get(reflection.name)
        autosave = reflection.options[:autosave]

        if records = associated_records_to_validate_or_save(association, @new_record_before_save, autosave)
          records.each do |record|
            next if record.destroyed?

            if autosave && record.marked_for_removal?
              remove_marked_for_removal_record(record, reflection, association)
            elsif autosave != false && (@new_record_before_save || record.new_record?)
              if autosave
                association.send(:insert_record, record, false, false)
              else
                association.send(:insert_record, record)
              end
            elsif autosave
              record.save(false)
            end
          end
        end

        # reconstruct the SQL queries now that we know the owner's id
        association.send(:construct_sql) if association.respond_to?(:construct_sql)
      end
    end

    # Saves the associated record if it's new or <tt>:autosave</tt> is enabled
    # on the association.
    #
    # In addition, it will destroy the association if it was marked for
    # destruction with mark_for_destruction.
    #
    # This all happens inside a transaction, _if_ the Transactions module is
    # included into ActiveRecord::Base after the AutosaveAssociation module,
    # which it does by default.
    def save_has_one_association(reflection)
      if (association = association_instance_get(reflection.name)) && !association.target.nil? && !association.destroyed?
        autosave = reflection.options[:autosave]

        if autosave && association.marked_for_removal?
          remove_marked_for_removal_record(association, reflection)
        else
          key = reflection.options[:primary_key] ? send(reflection.options[:primary_key]) : id
          if autosave != false && (new_record? || association.new_record? || association[reflection.primary_key_name] != key || autosave)
            association[reflection.primary_key_name] = key
            association.save(!autosave)
          end
        end
      end
    end

    # Saves the associated record if it's new or <tt>:autosave</tt> is enabled
    # on the association.
    #
    # In addition, it will destroy the association if it was marked for
    # destruction with mark_for_destruction.
    #
    # This all happens inside a transaction, _if_ the Transactions module is
    # included into ActiveRecord::Base after the AutosaveAssociation module,
    # which it does by default.
    def save_belongs_to_association(reflection)
      if (association = association_instance_get(reflection.name)) && !association.destroyed?
        autosave = reflection.options[:autosave]

        if autosave && association.marked_for_removal?
          remove_marked_for_removal_record(association, reflection)
        elsif autosave != false
          association.save(!autosave) if association.new_record? || autosave

          if association.updated?
            association_id = association.send(reflection.options[:primary_key] || :id)
            self[reflection.primary_key_name] = association_id
            # TODO: Removing this code doesn't seem to matter…
            if reflection.options[:polymorphic]
              self[reflection.options[:foreign_type]] = association.class.base_class.name.to_s
            end
          end
        end
      end
    end

    module AssociationCollectionExtension
      # Iterates over the association collection and marks the records for
      # destruction which _not_ included in the +records_or_ids+ array. Instead
      # of the records themselves, you can also pass the IDs of the records to
      # keep.
      #
      # You can optionally specify the +type+ of removal. See
      # #mark_for_removal! for more info.
      #
      # Note that this will always load the association target.
      #
      #   member.posts.map(&:id) # => [1, 2, 3, 4]
      #   member.posts.mark_missing_records_for_removal!([2, 3])
      #   member.posts[0].marked_for_removal? # => true
      #   member.posts[1].marked_for_removal? # => false
      #   member.posts[2].marked_for_removal? # => false
      #   member.posts[3].marked_for_removal? # => true
      #
      # Or with an array of records instead of their ids:
      #
      #   member.posts.mark_missing_records_for_removal!([member.posts[1], member.posts[2]])
      #   member.posts[0].marked_for_removal? # => true
      #   member.posts[1].marked_for_removal? # => false
      #   member.posts[2].marked_for_removal? # => false
      #   member.posts[3].marked_for_removal? # => true
      def mark_missing_records_for_removal!(records_or_ids, type = :destroy)
        ids = if records_or_ids.first.respond_to?(:new_record?)
          records_or_ids.map(&:id)
        else
          records_or_ids.map(&:to_i)
        end

        each do |record|
          record.mark_for_removal!(type) unless record.new_record? || ids.include?(record.id)
        end
      end
    end
  end
end

ActiveRecord::Associations::AssociationCollection.send(:include, ActiveRecord::AutosaveAssociation::AssociationCollectionExtension)