module Countrizable
  module ActiveRecord
    class Adapter
      # The cache caches attributes that already were looked up for read access.
      # The stash keeps track of new or changed values that need to be saved.
      attr_accessor :record, :stash
      private :record=, :stash=

      delegate :country_value_class, :to => :'record.class'

      def initialize(record)
        @record = record
        @stash = Attributes.new
      end

      def fetch_stash(country_code, name)
        stash.read(country_code, name)
      end

      delegate :contains?, :to => :stash, :prefix => :stash
      delegate :write, :to => :stash

      def fetch(country_code, name)
        record.countrizable_fallbacks(country_code).each do |fallback|
          value = stash.contains?(fallback, name) ? fetch_stash(fallback, name) : fetch_attribute(fallback, name)

          unless fallbacks_for?(value)
            set_metadata(value, :country_code => fallback, :requested_country_code => country_code)
            return value
          end
        end

        return nil
      end

      def save_country_values!
        stash.each do |country_code, attrs|
          next if attrs.empty?

          country_value = record.country_values_by_country_code[country_code] ||
                        record.country_values.build(country_code: country_code.to_s)
          attrs.each do |name, value|
            value = value.val if value.is_a?(Arel::Nodes::Casted)
            country_value[name] = value
          end

          ensure_foreign_key_for(country_value)
          country_value.save!
        end

        reset
      end

      def reset
        stash.clear
      end

      protected

      # Sometimes the country_values is initialised before a foreign key can be set.
      def ensure_foreign_key_for(country_value)
        # AR >= 4.1 reflections renamed to _reflections
        country_value[country_value.class.reflections.stringify_keys["countrizable_model"].foreign_key] = record.id
      end

      def type_cast(name, value)
        return value.presence unless column = column_for_attribute(name)

        column.type_cast value
      end

      def column_for_attribute(name)
        country_value_class.columns_hash[name.to_s]
      end

      def unserializable_attribute?(name, column)
        column.text? && country_value_class.serialized_attributes[name.to_s]
      end

      def fetch_attribute(country_code, name)
        country_value = record.country_value_for(country_code, false)
        if country_value
          country_value.send(name)
        else
          record.class.country_value_class.new.send(name)
        end
      end

      def set_metadata(object, metadata)
        object.country_value_metadata.merge!(metadata) if object.respond_to?(:country_value_metadata)
        object
      end

      def country_value_metadata_accessor(object)
        return if obj.respond_to?(:country_value_metadata)
        class << object; attr_accessor :country_value_metadata end
        object.country_value_metadata ||= {}
      end

      def fallbacks_for?(object)
        object.nil? || (fallbacks_for_empty_country_values? && object.blank?)
      end

      delegate :fallbacks_for_empty_country_values?, :to => :record, :prefix => false
      prepend AdapterDirty
    end
  end
end
