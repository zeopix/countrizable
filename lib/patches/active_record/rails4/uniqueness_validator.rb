require 'active_record/validations/uniqueness.rb'

module Countrizable
  module UniquenessValidatorOverride
    def validate_each(record, attribute, value)
      klass = record.class
      if klass.country_attributes? && klass.country_attributed?(attribute)
        finder_class = klass.country_value_class
        table = finder_class.arel_table

        relation = build_relation(finder_class, table, attribute, value).and(table[:locale].eq(Countrizable.locale))
        relation = relation.and(table[klass.reflect_on_association(:country_values).foreign_key].not_eq(record.send(:id))) if record.persisted?

        country_scopes = Array(options[:scope]) & klass.country_attribute_names
        uncountry_scopes = Array(options[:scope]) - country_scopes

        uncountry_scopes.each do |scope_item|
          scope_value = record.send(scope_item)
          reflection = klass.reflect_on_association(scope_item)
          if reflection
            scope_value = record.send(reflection.foreign_key)
            scope_item = reflection.foreign_key
          end
          relation = relation.and(find_finder_class_for(record).arel_table[scope_item].eq(scope_value))
        end

        country_scopes.each do |scope_item|
          scope_value = record.send(scope_item)
          relation = relation.and(table[scope_item].eq(scope_value))
        end

        if klass.unscoped.with_country_values.where(relation).exists?
          record.errors.add(attribute, :taken, options.except(:case_sensitive, :scope).merge(:value => value))
        end
      else
        super
      end
    end
  end
end

ActiveRecord::Validations::UniquenessValidator.send :prepend, Countrizable::UniquenessValidatorOverride