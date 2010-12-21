module ActiveRecord
  # = Active Record Through Association Scope
  module Associations
    module ThroughAssociationScope

      def scoped
        with_scope(@scope) do
          @reflection.klass.scoped &
          @reflection.through_reflection.klass.scoped
        end
      end

      protected

      def construct_find_scope
        {
          :conditions => construct_conditions,
          :joins      => construct_joins,
          :include    => @reflection.options[:include] || @reflection.source_reflection.options[:include],
          :select     => construct_select,
          :order      => @reflection.options[:order],
          :limit      => @reflection.options[:limit],
          :readonly   => @reflection.options[:readonly]
        }
      end

      def construct_create_scope
        {}
        #construct_owner_attributes(@reflection)
      end

      def aliased_through_table
        name = @reflection.through_reflection.table_name

        @reflection.table_name == name ?
          @reflection.through_reflection.klass.arel_table.alias(name + "_join") :
          @reflection.through_reflection.klass.arel_table
      end

      # Build SQL conditions from attributes, qualified by table name.
      def construct_conditions
        conditions = construct_owner_conditions(aliased_through_table, @reflection.through_reflection)
        conditions = conditions.and(Arel.sql(sql_conditions)) if sql_conditions
        conditions
      end

      # Conditions pointing to owner
      def construct_owner_conditions(table, reflection)
        if reflection.macro == :belongs_to
          table[reflection.klass.primary_key].
          eq(@owner[reflection.primary_key_name])
        else
          conditions =
            table[reflection.primary_key_name].
            eq(@owner[reflection.active_record_primary_key])

          if reflection.options[:as]
            conditions = conditions.and(
              table["#{reflection.options[:as]}_type"].
              in(sti_names(@owner.class))
            )
          end

          conditions
        end
      end

      def construct_from
        @reflection.table_name
      end

      def construct_select(custom_select = nil)
        distinct = "DISTINCT " if @reflection.options[:uniq]
        custom_select || @reflection.options[:select] || "#{distinct}#{@reflection.quoted_table_name}.*"
      end

      def construct_joins
        right = aliased_through_table
        left  = @reflection.klass.arel_table

        conditions = []

        if @reflection.source_reflection.macro == :belongs_to
          reflection_primary_key = @reflection.source_reflection.options[:primary_key] ||
                                   @reflection.klass.primary_key
          source_primary_key     = @reflection.source_reflection.primary_key_name

          if @reflection.options[:source_type]
            column    = @reflection.source_reflection.options[:foreign_type]
            sti_names = sti_names(@reflection.options[:source_type].to_s.constantize)

            conditions << right[column].in(sti_names)
          end
        else
          reflection_primary_key = @reflection.source_reflection.primary_key_name
          source_primary_key     = @reflection.source_reflection.options[:primary_key] ||
                                   @reflection.through_reflection.klass.primary_key
          if @reflection.source_reflection.options[:as]
            column    = "#{@reflection.source_reflection.options[:as]}_type"
            sti_names = sti_names(@reflection.through_reflection.klass)
            conditions << left[column].in(sti_names)
          end
        end

        conditions <<
          left[reflection_primary_key].eq(right[source_primary_key])

        right.create_join(
          right,
          right.create_on(right.create_and(conditions)))
      end

      # Construct attributes for :through pointing to owner and associate.
      def construct_join_attributes(associate)
        # TODO: revisit this to allow it for deletion, supposing dependent option is supported
        raise ActiveRecord::HasManyThroughCantAssociateThroughHasOneOrManyReflection.new(@owner, @reflection) if [:has_one, :has_many].include?(@reflection.source_reflection.macro)

        #join_attributes = construct_owner_attributes(@reflection.through_reflection).merge(@reflection.source_reflection.primary_key_name => associate.id)
        join_attributes = { @reflection.source_reflection.primary_key_name => associate.id }

        if @reflection.options[:source_type]
          join_attributes.merge!(@reflection.source_reflection.options[:foreign_type] => associate.class.name)
        end

        if @reflection.through_reflection.options[:conditions].is_a?(Hash)
          join_attributes.merge!(@reflection.through_reflection.options[:conditions])
        end

        join_attributes
      end

      def conditions
        @conditions = build_conditions unless defined?(@conditions)
        @conditions
      end

      def build_conditions
        association_conditions = @reflection.options[:conditions]
        through_conditions = build_through_conditions
        source_conditions = @reflection.source_reflection.options[:conditions]
        uses_sti = !@reflection.through_reflection.klass.descends_from_active_record?

        if association_conditions || through_conditions || source_conditions || uses_sti
          all = []

          [association_conditions, source_conditions].each do |conditions|
            all << interpolate_sql(sanitize_sql(conditions)) if conditions
          end

          all << through_conditions  if through_conditions
          all << build_sti_condition if uses_sti

          all.map { |sql| "(#{sql})" } * ' AND '
        end
      end

      def build_through_conditions
        conditions = @reflection.through_reflection.options[:conditions]
        if conditions.is_a?(Hash)
          interpolate_sql(@reflection.through_reflection.klass.send(:sanitize_sql, conditions)).gsub(
            @reflection.quoted_table_name,
            @reflection.through_reflection.quoted_table_name)
        elsif conditions
          interpolate_sql(sanitize_sql(conditions))
        end
      end

      def build_sti_condition
        @reflection.through_reflection.klass.send(:type_condition).to_sql
      end

      def sti_names(klass)
        ([klass] + klass.descendants).map { |m| m.sti_name }
      end

      alias_method :sql_conditions, :conditions
    end
  end
end
