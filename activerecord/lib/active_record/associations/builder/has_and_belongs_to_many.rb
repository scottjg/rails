module ActiveRecord::Associations::Builder
  class HasAndBelongsToMany < CollectionAssociation #:nodoc:
    def macro
      :has_and_belongs_to_many
    end

    def valid_options
      super + [:join_table, :association_foreign_key, :delete_sql, :insert_sql, :counter_cache]
    end

    def build
      reflection = super
      define_destroy_hook
      add_counter_cache_callbacks(reflection) if options[:counter_cache]
      reflection
    end

    def add_counter_cache_callbacks(reflection)
      cache_column = reflection.counter_cache_column
      klass = reflection.class_name.safe_constantize

      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def habtm_counter_cache_before_destroy_for_#{name}
          unless marked_for_destruction?
            ids = #{name.to_s.singularize}_ids
            #{klass}.decrement_counter(:#{cache_column}, ids) unless ids.empty?
          end
        end
      CODE

      model.before_destroy "habtm_counter_cache_before_destroy_for_#{name}"
      klass.attr_readonly cache_column if klass && klass.respond_to?(:attr_readonly)
    end

    def show_deprecation_warnings
      super

      [:delete_sql, :insert_sql].each do |name|
        if options.include? name
          ActiveSupport::Deprecation.warn("The :#{name} association option is deprecated. Please find an alternative (such as using has_many :through).")
        end
      end
    end

    def define_destroy_hook
      name = self.name
      model.send(:include, Module.new {
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def destroy_associations
            association(:#{name}).delete_all
            super
          end
        RUBY
      })
    end
  end
end
