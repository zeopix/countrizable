module Countrizable
  module ActiveRecord
    module ClassMethods
      delegate :values_country_codes, :set_country_values_table_name, :to => :country_value_class

      if ::ActiveRecord::VERSION::STRING < "5.0.0"
        def columns_hash
          super.except(*country_attribute_names.map(&:to_s))
        end
      end

      def with_country_codes(*country_code)
        all.merge country_value_class.with_country_codes(*country_codes)
      end

      def with_country_values(*country_codes)
        country_codes = values_country_codes if country_codes.empty?
        preload(:country_values).joins(:country_values).readonly(false).with_country_codes(country_codes).tap do |query|
          query.distinct! unless country_codes.flatten.one?
        end
      end

      def with_required_attributes
        warn 'with_required_attributes is deprecated and will be removed in the next release of Countrizable.'
        required_country_attributes.inject(all) do |scope, name|
          scope.where("#{country_column_name(name)} IS NOT NULL")
        end
      end

      def with_country_attribute(name, value, country = Countrizable.fallbacks)
        with_country_values.where(
          country_column_name(name)    => value,
          country_column_name(:country_code) => Array(country_codes).map(&:to_s)
        )
      end

      def country_attributed?(name)
        country_attribute_names.include?(name.to_sym)
      end

      def required_attributes
        warn 'required_attributes is deprecated and will be removed in the next release of Countrizable.'
        validators.map { |v| v.attributes if v.is_a?(ActiveModel::Validations::PresenceValidator) }.flatten
      end

      def required_country_attributes
        warn 'required_country_attributes is deprecated and will be removed in the next release of Countrizable.'
        country_attribute_names & required_attributes
      end

      def country_value_class
        @country_value_class ||= begin
          if self.const_defined?(:CountryValue, false)
            klass = self.const_get(:CountryValue, false)
          else
            klass = self.const_set(:CountryValue, Class.new(Countrizable::ActiveRecord::CountryValue))
          end

          klass.belongs_to :countrizable_model,
            class_name: self.name,
            foreign_key: country_value_options[:foreign_key],
            inverse_of: :country_values,
            touch: country_value_options.fetch(:touch, false)
          klass
        end
      end

      def country_values_table_name
        country_value_class.table_name
      end

      def country_column_name(name)
        "#{country_value_class.table_name}.#{name}"
      end

      private

      # Override the default relation method in order to return a subclass
      # of ActiveRecord::Relation with custom finder and calculation methods
      # for country attributes.
      def relation
        super.extending!(CountryAttributesQuery)
      end

      protected

      def define_country_attr_reader(name)
        define_method(name) do |*args|
          Countrizable::Interpolation.interpolate(name, self, args)
        end
        alias_method :"#{name}_before_type_cast", name
      end

      def define_country_attr_writer(name)
        define_method(:"#{name}=") do |value|
          write_attribute(name, value)
        end
      end

      def define_country_attr_accessor(name)
        attribute(name, ::ActiveRecord::Type::Value.new)
        define_country_attr_reader(name)
        define_country_attr_writer(name)
      end

      def define_country_values_reader(name)
        define_method(:"#{name}_country_values") do
          hash = country_attribute_by_country_code(name)
          countrizable.stash.keys.each_with_object(hash) do |country_code, result|
            result[country_code] = countrizable.fetch_stash(country_code, name) if countrizable.stash_contains?(country_code, name)
          end
        end
      end

      def define_country_values_writer(name)
        define_method(:"#{name}_country_values=") do |value|
          value.each do |(country_code, _value)|
            write_attribute name, _value, :country_code => country_code
          end
        end
      end

      def define_country_values_accessor(name)
        define_country_values_reader(name)
        define_country_values_writer(name)
      end
    end
  end
end