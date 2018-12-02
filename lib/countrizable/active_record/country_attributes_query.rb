module Countrizable
  module ActiveRecord
    module CountryAttributesQuery
      class WhereChain < ::ActiveRecord::QueryMethods::WhereChain
        def not(opts, *rest)
          if parsed = @scope.clone.parse_country_conditions(opts)
            @scope.join_country_values.where.not(parsed, *rest)
          else
            super
          end
        end
      end

      def where(opts = :chain, *rest)
        if opts == :chain
          WhereChain.new(spawn)
        elsif parsed = parse_country_conditions(opts)
          join_country_values(super(parsed, *rest))
        else
          super
        end
      end

      def having(opts, *rest)
        if parsed = parse_country_conditions(opts)
          join_country_values(super(parsed, *rest))
        else
          super
        end
      end

      def order(opts, *rest)
        if respond_to?(:country_attribute_names) && parsed = parse_countries_order(opts)
          join_country_values super(parsed)
        else
          super
        end
      end

      def reorder(opts, *rest)
        if respond_to?(:country_attribute_names) && parsed = parse_countries_order(opts)
          join_country_values super(parsed)
        else
          super
        end
      end

      def group(*columns)
        if respond_to?(:country_attribute_names) && parsed = parse_countries_columns(columns)
          join_country_values super(parsed)
        else
          super
        end
      end

      def select(*columns)
        if respond_to?(:country_attribute_names) && parsed = parse_countries_columns(columns)
          join_country_values super(parsed)
        else
          super
        end
      end

      def exists?(conditions = :none)
        if parsed = parse_country_conditions(conditions)
          with_country_values_in_fallbacks.exists?(parsed)
        else
          super
        end
      end

      def calculate(*args)
        column_name = args[1]
        if respond_to?(:country_attribute_names) && country_column?(column_name)
          args[1] = country_column_name(column_name)
          join_country_values.calculate(*args)
        else
          super
        end
      end

      def pluck(*column_names)
        if respond_to?(:country_values_attribute_names) && parsed = parse_countries_columns(column_names)
          join_country_values.pluck(*parsed)
        else
          super
        end
      end

      def with_country_values_in_fallbacks
        with_country_values(Countrizable.fallbacks)
      end

      def parse_country_conditions(opts)
        if opts.is_a?(Hash) && respond_to?(:country_attribute_names) && (keys = opts.symbolize_keys.keys & country_attribute_names).present?
          opts = opts.dup
          keys.each { |key| opts[country_column_name(key)] = opts.delete(key) || opts.delete(key.to_s) }
          opts
        end
      end

      if ::ActiveRecord::VERSION::STRING < "5.0.0"
        def where_values_hash(*args)
          return super unless respond_to?(:country_values_table_name)
          equalities = respond_to?(:with_default_scope) ? with_default_scope.where_values : where_values
          equalities = equalities.grep(Arel::Nodes::Equality).find_all { |node|
            node.left.relation.name == country_values_table_name
          }

          binds = Hash[bind_values.find_all(&:first).map { |column, v| [column.name, v] }]

          super.merge(Hash[equalities.map { |where|
            name = where.left.name
            [name, binds.fetch(name.to_s) { right = where.right; right.is_a?(Arel::Nodes::Casted) ? right.val : right }]
          }])
        end
      end

      def join_country_values(relation = self)
        if relation.joins_values.include?(:country_values)
          relation
        else
          relation.with_country_values_in_fallbacks
        end
      end

      private

      def arel_countries_order_node(column, direction)
        unless countries_column?(column)
          return self.arel_table[column].send(direction)
        end

        full_column = countries_column_name(column)

        # Inject `full_column` to the select values to avoid
        # PG::InvalidColumnReference errors with distinct queries on Postgres
        if select_values.empty?
          self.select_values = [self.arel_table[Arel.star], full_column]
        else
          self.select_values << full_column
        end

        country_value_class.arel_table[column].send(direction)
      end

      def parse_countries_order(opts)
        case opts
        when Hash
          # Do not process nothing unless there is at least a country column
          # so that the `order` statement will be processed by the original
          # ActiveRecord method
          return nil unless opts.find { |col, dir| country_column?(col) }

          # Build order arel nodes for countrys and non-countries statements
          ordering = opts.map do |column, direction|
            arel_country_order_node(column, direction)
          end

          order(ordering).order_values
        when Symbol
          parse_countries_order({ opts => :asc })
        when Array
          parse_countries_order(Hash[opts.collect { |opt| [opt, :asc] } ])
        else # failsafe returns nothing
          nil
        end
      end

      def parse_countries_columns(columns)
        if columns.is_a?(Array) && (columns.flatten & country_attribute_names).present?
          columns.flatten.map { |column| country_column?(column) ? country_column_name(column) : column }
        end
      end

      def country_column?(column)
        country_attribute_names.include?(column)
      end
    end
  end
end