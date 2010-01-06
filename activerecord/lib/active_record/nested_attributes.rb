module ActiveRecord
  module NestedAttributes #:nodoc:
    class TooManyRecords < ActiveRecordError
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.class_inheritable_accessor :nested_attributes_options, :instance_writer => false
      base.nested_attributes_options = {}
    end

    # == Nested Attributes
    #
    # Nested attributes allow you to save attributes on associated records
    # through the parent. By default nested attribute updating is turned off,
    # you can enable it using the accepts_nested_attributes_for class method.
    # When you enable nested attributes an attribute writer is defined on
    # the model.
    #
    # The attribute writer is named after the association, which means that
    # in the following example, two new methods are added to your model:
    # <tt>author_attributes=(attributes)</tt> and
    # <tt>pages_attributes=(attributes)</tt>.
    #
    #   class Book < ActiveRecord::Base
    #     has_one :author
    #     has_many :pages
    #
    #     accepts_nested_attributes_for :author, :pages
    #   end
    #
    # Note that the <tt>:autosave</tt> option is automatically enabled on every
    # association that accepts_nested_attributes_for is used for.
    #
    # === One-to-one
    #
    # Consider a Member model that has one Avatar:
    #
    #   class Member < ActiveRecord::Base
    #     has_one :avatar
    #     accepts_nested_attributes_for :avatar
    #   end
    #
    # Enabling nested attributes on a one-to-one association allows you to
    # create the member and avatar in one go:
    #
    #   params = { :member => { :name => 'Jack', :avatar_attributes => { :icon => 'smiling' } } }
    #   member = Member.create(params)
    #   member.avatar.id # => 2
    #   member.avatar.icon # => 'smiling'
    #
    # It also allows you to update the avatar through the member:
    #
    #   params = { :member' => { :avatar_attributes => { :id => '2', :icon => 'sad' } } }
    #   member.update_attributes params['member']
    #   member.avatar.icon # => 'sad'
    #
    # By default you will only be able to set and update attributes on the
    # associated model. If you want to destroy the associated model through the
    # attributes hash, you have to enable it first by setting the
    # <tt>:allow</tt> option to one of <tt>:destroy</tt>, <tt>:delete</tt>, or
    # <tt>:nullify</tt>:
    #
    #   class Member < ActiveRecord::Base
    #     has_one :avatar
    #     accepts_nested_attributes_for :avatar, :allow => :destroy
    #   end
    #
    # Now, when you add the <tt>mark_for_removal</tt> key to the attributes
    # hash, with a value that evaluates to +true+, you will destroy the
    # associated model:
    #
    #   member.avatar_attributes = { :id => '2', :mark_for_removal => '1' }
    #   member.avatar.marked_for_removal? # => true
    #   member.save
    #   member.avatar #=> nil
    #
    # Note that the model will _not_ be destroyed until the parent is saved.
    #
    # === One-to-many
    #
    # Consider a member that has a number of posts:
    #
    #   class Member < ActiveRecord::Base
    #     has_many :posts
    #     accepts_nested_attributes_for :posts
    #   end
    #
    # You can now set or update attributes on an associated post model through
    # the attribute hash.
    #
    # For each hash that does _not_ have an <tt>id</tt> key a new record will
    # be instantiated, unless the hash also contains a <tt>mark_for_removal</tt> key
    # that evaluates to +true+.
    #
    #   params = { :member => {
    #     :name => 'joe', :posts_attributes => [
    #       { :title => 'Kari, the awesome Ruby documentation browser!' },
    #       { :title => 'The egalitarian assumption of the modern citizen' },
    #       { :title => '', :mark_for_removal => '1' } # this will be ignored
    #     ]
    #   }}
    #
    #   member = Member.create(params['member'])
    #   member.posts.length # => 2
    #   member.posts.first.title # => 'Kari, the awesome Ruby documentation browser!'
    #   member.posts.second.title # => 'The egalitarian assumption of the modern citizen'
    #
    # You may also set a :reject_if proc to silently ignore any new record
    # hashes if they fail to pass your criteria. For example, the previous
    # example could be rewritten as:
    #
    #    class Member < ActiveRecord::Base
    #      has_many :posts
    #      accepts_nested_attributes_for :posts, :reject_if => proc { |attributes| attributes['title'].blank? }
    #    end
    #
    #   params = { :member => {
    #     :name => 'joe', :posts_attributes => [
    #       { :title => 'Kari, the awesome Ruby documentation browser!' },
    #       { :title => 'The egalitarian assumption of the modern citizen' },
    #       { :title => '' } # this will be ignored because of the :reject_if proc
    #     ]
    #   }}
    #
    #   member = Member.create(params['member'])
    #   member.posts.length # => 2
    #   member.posts.first.title # => 'Kari, the awesome Ruby documentation browser!'
    #   member.posts.second.title # => 'The egalitarian assumption of the modern citizen'
    #
    #  Alternatively, :reject_if also accepts a symbol for using methods:
    #
    #    class Member < ActiveRecord::Base
    #      has_many :posts
    #      accepts_nested_attributes_for :posts, :reject_if => :new_record?
    #    end
    #
    #    class Member < ActiveRecord::Base
    #      has_many :posts
    #      accepts_nested_attributes_for :posts, :reject_if => :reject_posts
    #
    #      def reject_posts(attributed)
    #        attributed['title].blank?
    #      end
    #    end
    #
    # If the hash contains an <tt>id</tt> key that matches an already
    # associated record, the matching record will be modified:
    #
    #   member.attributes = {
    #     :name => 'Joe',
    #     :posts_attributes => [
    #       { :id => 1, :title => '[UPDATED] An, as of yet, undisclosed awesome Ruby documentation browser!' },
    #       { :id => 2, :title => '[UPDATED] other post' }
    #     ]
    #   }
    #
    #   member.posts.first.title # => '[UPDATED] An, as of yet, undisclosed awesome Ruby documentation browser!'
    #   member.posts.second.title # => '[UPDATED] other post'
    #
    # By default the associated records are protected from being destroyed. If
    # you want to destroy any of the associated records through the attributes
    # hash, you have to enable it first by setting the <tt>:allow</tt> option
    # to one of <tt>:destroy</tt>, <tt>:delete</tt>, or <tt>:nullify</tt>:
    #
    #   class Member < ActiveRecord::Base
    #     has_many :posts
    #     accepts_nested_attributes_for :posts, :allow => :destroy
    #   end
    #
    # Now, when you add the <tt>mark_for_removal</tt> key to the attributes
    # hash, with a value that evaluates to +true+, you will destroy the
    # associated model:
    #
    #   params = { :member => {
    #     :posts_attributes => [{ :id => '2', :mark_for_removal => '1' }]
    #   }}
    #
    #   member.attributes = params['member']
    #   member.posts.detect { |p| p.id == 2 }.marked_for_removal? # => true
    #   member.posts.length #=> 2
    #   member.save
    #   member.posts.length # => 1
    #
    # Note that the member will _not_ be destroyed until the parent is saved.
    #
    # === Saving
    #
    # All changes to models, including the removal of those marked for removal,
    # are saved and removed automatically and atomically when the parent model
    # is saved. This happens inside the transaction initiated by the parents
    # save method. See ActiveRecord::AutosaveAssociation.
    module ClassMethods
      REJECT_ALL_BLANK_PROC = proc { |attributes| attributes.all? { |_, value| value.blank? } }

      # Defines an attributes writer for the specified association(s). If you
      # are using <tt>attr_protected</tt> or <tt>attr_accessible</tt>, then you
      # will need to add the attribute writer to the allowed list.
      #
      # Supported options:
      # [:allow]
      #   If set to a valid #mark_for_removal! type (<tt>:destroy</tt>,
      #   <tt>:delete</tt>, or <tt>:nullify</tt>), removes any members from the
      #   attributes hash with a <tt>mark_for_removal</tt> key and a value that
      #   evaluates to +true+ (eg. 1, '1', true, or 'true'). This option is off
      #   by default.
      # [:destroy_missing]
      #   If true, destroys any members from the association collection for
      #   which _no_ +ID+ is available in the attributes hash. Note that this
      #   option is only applicable to collection associations. This option is
      #   off by default.
      # [:reject_if]
      #   Allows you to specify a Proc or a Symbol pointing to a method that
      #   checks whether a record should be built for a certain attribute hash.
      #   The hash is passed to the supplied Proc or the method and it should
      #   return either +true+ or +false+. When no :reject_if is specified, a
      #   record will be built for all attribute hashes that do not have a
      #   <tt>mark_for_removal</tt> value that evaluates to true. Passing
      #   <tt>:all_blank</tt> instead of a Proc will create a proc that will
      #   reject a record where all the attributes are blank.
      # [:limit]
      #   Allows you to specify the maximum number of the associated records
      #   that can be processes with the nested attributes. If the size of the
      #   nested attributes array exceeds the specified limit,
      #   NestedAttributes::TooManyRecords exception is raised. If omitted, any
      #   number of members can be processed. Note that this option is only
      #   applicable to collection associations.
      # [:update_only]
      #   Allows you to specify that an existing record may only be updated. A
      #   new record may only be created when there is no existing record. Note
      #   that this option is only applicable to one-to-one associations. This
      #   option is off by default.
      #
      # Examples:
      #   # creates avatar_attributes=
      #   accepts_nested_attributes_for :avatar, :reject_if => proc { |attributes| attributes['name'].blank? }
      #   # creates avatar_attributes=
      #   accepts_nested_attributes_for :avatar, :reject_if => :all_blank
      #   # creates avatar_attributes= and posts_attributes=
      #   accepts_nested_attributes_for :avatar, :allow => :destroy
      #   accepts_nested_attributes_for :posts, :destroy_missing => true
      def accepts_nested_attributes_for(*attr_names)
        options = { :update_only => false }
        options.update(attr_names.extract_options!)
        options.assert_valid_keys(:allow, :allow_destroy, :destroy_missing, :reject_if, :limit, :update_only)
        options[:reject_if] = REJECT_ALL_BLANK_PROC if options[:reject_if] == :all_blank

        if allow_destroy = options.delete(:allow_destroy)
          ActiveSupport::Deprecation.warn ":allow_destroy is deprecated for accepts_nested_attributes_for. Use `:allow => :destroy' instead."
          options[:allow] = :destroy if allow_destroy
        end

        attr_names.each do |association_name|
          if reflection = reflect_on_association(association_name)
            reflection.options[:autosave] = true
            add_autosave_association_callbacks(reflection)
            nested_attributes_options[association_name.to_sym] = options
            type = (reflection.collection_association? ? :collection : :one_to_one)

            # def pirate_attributes=(attributes)
            #   assign_nested_attributes_for_one_to_one_association(:pirate, attributes)
            # end
            class_eval %{
              def #{association_name}_attributes=(attributes)
                assign_nested_attributes_for_#{type}_association(:#{association_name}, attributes)
              end
            }, __FILE__, __LINE__
          else
            raise ArgumentError, "No association found for name `#{association_name}'. Has it been defined yet?"
          end
        end
      end
    end

    # Returns ActiveRecord::AutosaveAssociation::marked_for_removal? It's
    # used in conjunction with fields_for to build a form element for the
    # destruction of this association.
    #
    # See ActionView::Helpers::FormHelper::fields_for for more info.
    def mark_for_removal
      marked_for_removal?
    end

    # Returns ActiveRecord::AutosaveAssociation::marked_for_removal? It's
    # used in conjunction with fields_for to build a form element for the
    # destruction of this association.
    #
    # See ActionView::Helpers::FormHelper::fields_for for more info.
    #
    # Deprecated: Use #mark_for_removal instead.
    def _destroy
      ActiveSupport::Deprecation.warn "#_destroy is deprecated in nested attributes. Use #mark_for_removal instead."
      marked_for_removal?
    end

    private

    # Attribute hash keys that should not be assigned as normal attributes.
    # These hash keys are nested attributes implementation details.
    UNASSIGNABLE_KEYS = %w( id mark_for_removal _destroy )

    # Assigns the given attributes to the association.
    #
    # If update_only is false and the given attributes include an <tt>:id</tt>
    # that matches the existing record’s id, then the existing record will be
    # modified. If update_only is true, a new record is only created when no
    # object exists. Otherwise a new record will be built.
    #
    # If the given attributes include a matching <tt>:id</tt> attribute, or
    # update_only is true, and a <tt>:mark_for_removal</tt> key set to a truthy
    # value, then the existing record will be marked for removal.
    def assign_nested_attributes_for_one_to_one_association(association_name, attributes)
      options = nested_attributes_options[association_name]
      attributes = attributes.with_indifferent_access
      check_existing_record = (options[:update_only] || !attributes['id'].blank?)

      if check_existing_record && (record = send(association_name)) &&
          (options[:update_only] || record.id.to_s == attributes['id'].to_s)
        assign_to_or_mark_for_removal(record, attributes, options[:allow])

      elsif attributes['id']
        raise_nested_attributes_record_not_found(association_name, attributes['id'])

      elsif !reject_new_record?(association_name, attributes)
        method = "build_#{association_name}"
        if respond_to?(method)
          send(method, attributes.except(*UNASSIGNABLE_KEYS))
        else
          raise ArgumentError, "Cannot build association #{association_name}. Are you trying to build a polymorphic one-to-one association?"
        end
      end
    end

    # Assigns the given attributes to the collection association.
    #
    # Hashes with an <tt>:id</tt> value matching an existing associated record
    # will update that record. Hashes without an <tt>:id</tt> value will build
    # a new record for the association. Hashes with a matching <tt>:id</tt>
    # value and a <tt>:mark_for_removal</tt> key set to a truthy value will mark the
    # matched record for removal.
    #
    # For example:
    #
    #   assign_nested_attributes_for_collection_association(:people, {
    #     '1' => { :id => '1', :name => 'Peter' },
    #     '2' => { :name => 'John' },
    #     '3' => { :id => '2', :mark_for_removal => true }
    #   })
    #
    # Will update the name of the Person with ID 1, build a new associated
    # person with the name `John', and mark the associatied Person with ID 2
    # for removal.
    #
    # Also accepts an Array of attribute hashes:
    #
    #   assign_nested_attributes_for_collection_association(:people, [
    #     { :id => '1', :name => 'Peter' },
    #     { :name => 'John' },
    #     { :id => '2', :mark_for_removal => true }
    #   ])
    def assign_nested_attributes_for_collection_association(association_name, attributes_collection)
      options = nested_attributes_options[association_name]

      unless attributes_collection.is_a?(Hash) || attributes_collection.is_a?(Array)
        raise ArgumentError, "Hash or Array expected, got #{attributes_collection.class.name} (#{attributes_collection.inspect})"
      end

      if options[:limit] && attributes_collection.size > options[:limit]
        raise TooManyRecords, "Maximum #{options[:limit]} records are allowed. Got #{attributes_collection.size} records instead."
      end

      if attributes_collection.is_a? Hash
        attributes_collection = attributes_collection.sort_by { |index, _| index.to_i }.map { |_, attributes| attributes }
      end

      # This list is to keep track of the records which are _not_ missing from the attributes.
      records_to_keep = []

      attributes_collection.each do |attributes|
        attributes = attributes.with_indifferent_access

        if attributes['id'].blank?
          unless reject_new_record?(association_name, attributes)
            send(association_name).build(attributes.except(*UNASSIGNABLE_KEYS))
          end
        elsif existing_record = send(association_name).detect { |record| record.id.to_s == attributes['id'].to_s }
          records_to_keep << existing_record
          assign_to_or_mark_for_removal(existing_record, attributes, options[:allow])
        else
          raise_nested_attributes_record_not_found(association_name, attributes['id'])
        end
      end

      send(association_name).mark_missing_records_for_removal!(records_to_keep) if options[:destroy_missing]
    end

    # Updates a record with the +attributes+ or marks it for removal if
    # +removal_type+ is not +nil+ and has_removal_flag? returns +true+.
    def assign_to_or_mark_for_removal(record, attributes, removal_type)
      if removal_type && has_removal_flag?(attributes)
        record.mark_for_removal!(removal_type)
      else
        record.attributes = attributes.except(*UNASSIGNABLE_KEYS)
      end
    end

    # Determines if a hash contains a truthy `mark_for_removal' key.
    def has_removal_flag?(hash)
      if ConnectionAdapters::Column.value_to_boolean(hash['_destroy'])
        ActiveSupport::Deprecation.warn "#_destroy is deprecated in nested attributes. Use #mark_for_removal instead."
        true
      end || ConnectionAdapters::Column.value_to_boolean(hash['mark_for_removal'])
    end

    # Determines if a new record should be build by checking for
    # has_removal_flag? or if a <tt>:reject_if</tt> proc exists for this
    # association and evaluates to +true+.
    def reject_new_record?(association_name, attributes)
      has_removal_flag?(attributes) || call_reject_if(association_name, attributes)
    end

    def call_reject_if(association_name, attributes)
      case callback = nested_attributes_options[association_name][:reject_if]
      when Symbol
        method(callback).arity == 0 ? send(callback) : send(callback, attributes)
      when Proc
        callback.call(attributes)
      end
    end

    def raise_nested_attributes_record_not_found(association_name, record_id)
      reflection = self.class.reflect_on_association(association_name)
      raise RecordNotFound, "Couldn't find #{reflection.klass.name} with ID=#{record_id} for #{self.class.name} with ID=#{id}"
    end
  end
end
