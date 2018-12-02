module Countrizable
  module Validations
    module UniquenessValidator
      def validate_each(record, attribute, value)
        klass = record.class
        if klass.country_attributes? && klass.country_attributed?(attribute)
          finder_class = klass.country_value_class
          finder_table = finder_class.arel_table
          relation = build_relation(finder_class, finder_table, attribute, value).where(country_code: Countrizable.country_code)
          relation = relation.where.not(klass.reflect_on_association(:country_values).foreign_key => record.send(:id)) if record.persisted?


          country_scopes = Array(options[:scope]) & klass.country_attribute_names
          uncountry_scopes = Array(options[:scope]) - country_scopes

          relation = relation.joins(:countrizable_model) if uncountry_scopes.present?
          uncountry_scopes.each do |scope_item|
            scope_value = record.send(scope_item)
            reflection = klass.reflect_on_association(scope_item)
            if reflection
              scope_value = record.send(reflection.foreign_key)
              scope_item = reflection.foreign_key
            end
            relation = relation.where(find_finder_class_for(record).table_name => { scope_item => scope_value })
          end

          country_scopes.each do |scope_item|
            scope_value = record.send(scope_item)
            relation = relation.where(scope_item => scope_value)
          end
          relation = relation.merge(options[:conditions]) if options[:conditions]

          # if klass.unscoped.with_country_values.where(relation).exists?
          if relation.exists?
            error_options = options.except(:case_sensitive, :scope, :conditions)
            error_options[:value] = value
            record.errors.add(attribute, :taken, error_options)
          end
        else
          super(record, attribute, value)
        end
      end
    end
  end
end

ActiveRecord::Validations::UniquenessValidator.prepend Countrizable::Validations::UniquenessValidator