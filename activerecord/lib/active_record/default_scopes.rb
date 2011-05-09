require 'active_support/core_ext/class/attribute'

module ActiveRecord
  module DefaultScopes
    extend ActiveSupport::Concern

    included do
      # Stores the default scopes, and default selects for the class
      class_attribute :default_scopes, :instance_writer => false
      self.default_scopes = []
    end

    module ClassMethods
      # Use this macro in your model to set a default scope for all operations on
      # the model.
      #
      #   class Article < ActiveRecord::Base
      #     default_scope where(:published => true)
      #   end
      #
      #   Article.all # => SELECT * FROM articles WHERE published = true
      #
      # The <tt>default_scope</tt> is also applied while creating/building a record. It is not
      # applied while updating a record.
      #
      #   Article.new.published    # => true
      #   Article.create.published # => true
      #
      # You can also use <tt>default_scope</tt> with a block, in order to have it lazily evaluated:
      #
      #   class Article < ActiveRecord::Base
      #     default_scope { where(:published_at => Time.now - 1.week) }
      #   end
      #
      # (You can also pass any object which responds to <tt>call</tt> to the <tt>default_scope</tt>
      # macro, and it will be called when building the default scope.)
      #
      # If you use multiple <tt>default_scope</tt> declarations in your model then they will
      # be merged together:
      #
      #   class Article < ActiveRecord::Base
      #     default_scope where(:published => true)
      #     default_scope where(:rating => 'G')
      #   end
      #
      #   Article.all # => SELECT * FROM articles WHERE published = true AND rating = 'G'
      #
      # This is also the case with inheritance and module includes where the parent or module
      # defines a <tt>default_scope</tt> and the child or including class defines a second one.
      #
      # If you need to do more complex things with a default scope, you can alternatively
      # define it as a class method:
      #
      #   class Article < ActiveRecord::Base
      #     def self.default_scope
      #       # Should return a scope, you can call 'super' here etc.
      #     end
      #   end
      def default_scope(scope = {})
        scope = Proc.new if block_given?
        self.default_scopes = default_scopes.dup << { :scope => scope, :type => :scope }
      end

      # Use this macro in your model to set a default select scope for all operations on
      # the model.
      #
      #   class Article < ActiveRecord::Base
      #     default_select where(:published => true)
      #   end
      #
      #   Article.all # => SELECT * FROM articles WHERE published = true
      #
      # The <tt>default_select</tt> is not applied while creating/building or updating a record.
      #
      # You can also use <tt>default_select</tt> with a block, in order to have it lazily evaluated:
      #
      #   class Article < ActiveRecord::Base
      #     default_select { where(:published_at => Time.now - 1.week) }
      #   end
      #
      # (You can also pass any object which responds to <tt>call</tt> to the <tt>default_select</tt>
      # macro, and it will be called when building the default select scope.)
      #
      # If you use multiple <tt>default_select</tt> declarations in your model then they will
      # be merged together:
      #
      #   class Article < ActiveRecord::Base
      #     default_select where(:published => true)
      #     default_select where(:rating => 'G')
      #   end
      #
      #   Article.all # => SELECT * FROM articles WHERE published = true AND rating = 'G'
      #
      # This is also the case with inheritance and module includes where the parent or module
      # defines a <tt>default_select</tt> and the child or including class defines a second one.
      #
      # If you need to do more complex things with a default select, you can alternatively
      # define it as a class method:
      #
      #   class Article < ActiveRecord::Base
      #     def self.default_select
      #       # Should return a scope, you can call 'super' here etc.
      #     end
      #   end
      def default_select(scope = {})
        scope = Proc.new if block_given?
        self.default_scopes = default_scopes.dup << { :scope => scope, :type => :select }
      end

      private

      def build_default_scope(options = {}) #:nodoc:
        type_selection = options[:type]

        # Use relation for scoping to ensure we ignore whatever the current value of
        # self.current_scope may be.
        default_scoping = relation
        default_scoping = add_default_scoping(:scope,  default_scoping, type_selection) { default_scope }
        default_scoping = add_default_scoping(:select, default_scoping, type_selection) { default_select }
        default_scoping
      end

      def add_default_scoping(scope_type, default_scoping, type, &block)
        if method(:"default_#{scope_type}").owner != Base.singleton_class
          default_scoping.scoping(&block)
        elsif default_scopes_available_for_merging(type, scope_type)
          merge_default_scopes(default_scoping, scope_type)
        else
          default_scoping
        end
      end

      def default_scopes_available_for_merging(type, scope_type)
        (type.nil? || type == scope_type) && default_scopes.any? { |s| s[:type] == scope_type }
      end

      def merge_default_scopes(default_scoping, type)
        default_scopes.inject(default_scoping) do |default_scope, scope_hash|
          scope = scope_hash[:scope]
          if scope.is_a?(Hash)
            default_scope.apply_finder_options(scope)
          elsif !scope.is_a?(Relation) && scope.respond_to?(:call)
            default_scope.merge(scope.call)
          else
            default_scope.merge(scope)
          end
        end
      end

    end
  end
end