# Helper class for storing values per country_codes. Used by Countrizable::Adapter
# to stash and cache attribute values.

module Countrizable
  module ActiveRecord
    class Attributes < Hash # TODO: Think about using HashWithIndifferentAccess ?
      def [](country_code)
        country_code = country_code.to_sym
        self[country_code] = {} unless has_key?(country_code)
        self.fetch(country_code)
      end

      def contains?(country_code, name)
        self[country_code].has_key?(name.to_s)
      end

      def read(country_code, name)
        self[country_code][name.to_s]
      end

      def write(country_code, name, value)
        self[country_code][name.to_s] = value
      end
    end
  end
end