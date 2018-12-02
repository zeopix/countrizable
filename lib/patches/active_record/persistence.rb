module Countrizable
  module Persistence
    # Updates the associated record with values matching those of the instance attributes.
    # Returns the number of affected rows.
    def _update_record(attribute_names = self.attribute_names)
      attribute_names_without_country_attributed = attribute_names.select{ |k| not respond_to?('country_attributed?') or not country_attributed?(k) }
      super(attribute_names_without_country_attributed)
    end

    def _create_record(attribute_names = self.attribute_names)
      attribute_names_without_country_attributed = attribute_names.select{ |k| not respond_to?('country_attributed?') or not country_attributed?(k) }
      super(attribute_names_without_country_attributed)
    end
  end
end

ActiveRecord::Persistence.send(:prepend, Countrizable::Persistence)