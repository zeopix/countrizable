module Countrizable
  module ActiveRecord
    class CountryValue < ::ActiveRecord::Base

      validates :country_code, :presence => true

      class << self
        # Sometimes ActiveRecord queries .table_exists? before the table name
        # has even been set which results in catastrophic failure.
        def table_exists?
          table_name.present? && super
        end

        def with_country_codes(*country_codes)
          # Avoid using "IN" with SQL queries when only using one locale.
          country_codes = country_codes.flatten.map(&:to_s)
          country_codes = country_codes.first if country_codes.one?
          where :country_code => country_codes
        end
        alias with_country_codes with_country_codes

        def valued_country_codes #prev translated_locales
          select('DISTINCT country_code').order(:country_code).map(&:country_code)
        end
      end

      def country_code
        _country_code = read_attribute :country_code
        _country_code.present? ? _country_code.to_sym : _country_code
      end

      def country_code=(country_code)
        write_attribute :country_code, country_code.to_s
      end
    end
  end
end

# Setting this will force polymorphic associations to subclassed objects
# to use their table_name rather than the parent object's table name,
# which will allow you to get their models back in a more appropriate
# format.
#
# See http://www.ruby-forum.com/topic/159894 for details.
Countrizable::ActiveRecord::CountryValue.abstract_class = true
