if ::ActiveRecord::VERSION::STRING >= "5.0.0"
  module Countrizable
    module Relation
      def where_values_hash(relation_table_name = table_name)
        return super unless respond_to?(:country_values_table_name)
        super.merge(super(country_values_table_name))
      end
    end
  end

  ActiveRecord::Relation.prepend Countrizable::Relation
end