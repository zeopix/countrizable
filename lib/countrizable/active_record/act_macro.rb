module Countrizable
  module ActiveRecord
    module ActMacro
      def country_attribute(*attr_names)
        options = attr_names.extract_options!
        # Bypass setup_countries! if the initial bootstrapping is done already.
        setup_countries!(options) unless country_attribute?
        check_columns!(attr_names)

        # Add any extra country attributes.
        attr_names = attr_names.map(&:to_sym)
        attr_names -= country_attribute_names if defined?(country_attribute_names)

        allow_country_of_attributes(attr_names) if attr_names.present?
      end

      def class_name
        @class_name ||= begin
          class_name = table_name[table_name_prefix.length..-(table_name_suffix.length + 1)].downcase.camelize
          pluralize_table_names ? class_name.singularize : class_name
        end
      end

      def country_attribute?
        included_modules.include?(InstanceMethods)
      end

      protected

      def allow_country_of_attributes(attr_names)
        attr_names.each do |attr_name|
          # Detect and apply serialization.
          enable_serializable_attribute(attr_name)

          # Create accessors for the attribute.
          define_country_attr_accessor(attr_name)
          define_country_values_accessor(attr_name)

          # Add attribute to the list.
          self.country_attribute_names << attr_name
        end

        begin
          if ::ActiveRecord::VERSION::STRING > "5.0" && table_exists? && country_value_class.table_exists?
            self.ignored_columns += country_attribute_names.map(&:to_s)
            reset_column_information
          end
        rescue ::ActiveRecord::NoDatabaseError
          warn 'Unable to connect to a database. Countrizable skipped ignoring columns of country attributes.'
        end
      end

      def check_columns!(attr_names)
        # If tables do not exist or Rails version is greater than 5, do not warn about conflicting columns
        return unless ::ActiveRecord::VERSION::STRING < "5.0" && table_exists? && country_value_class.table_exists?
        if (overlap = attr_names.map(&:to_s) & column_names).present?
          ActiveSupport::Deprecation.warn(
            ["You have defined one or more country attributes with names that conflict with column(s) on the model table. ",
             "Countrizable does not support this configuration anymore, remove or rename column(s) on the model table.\n",
             "Model name (table name): #{model_name} (#{table_name})\n",
             "Attribute name(s): #{overlap.join(', ')}\n"].join
          )
        end
      rescue ::ActiveRecord::NoDatabaseError
        warn 'Unable to connect to a database. Countrizable skipped checking attributes with conflicting column names.'
      end

      def apply_countrizable_options(options)
        options[:table_name] ||= "#{table_name.singularize}_country_values"
        options[:foreign_key] ||= class_name.foreign_key

        class_attribute :country_attribute_names, :country_value_options, :fallbacks_for_empty_country_values
        self.country_attribute_names = []
        self.country_value_options        = options
        self.fallbacks_for_empty_country_values = options[:fallbacks_for_empty_country_values]
      end

      def enable_serializable_attribute(attr_name)
        serializer = self.countrizable_serialized_attributes[attr_name]
        if serializer.present?
          if defined?(::ActiveRecord::Coders::YAMLColumn) &&
            serializer.is_a?(::ActiveRecord::Coders::YAMLColumn)
            serializer = serializer.object_class
          end

          country_value_class.send :serialize, attr_name, serializer
        end
      end

      def setup_countries!(options)
        apply_countrizable_options(options)

        include InstanceMethods
        extend  ClassMethods, Migration

        country_value_class.table_name = options[:table_name]

        has_many :country_values, :class_name  => country_value_class.name,
                                :foreign_key => options[:foreign_key],
                                :dependent   => :destroy,
                                :extend      => HasManyExtensions,
                                :autosave    => false,
                                :inverse_of  => :countrizable_model

        after_create :save_country_values!
        after_update :save_country_values!
      end
    end

    module HasManyExtensions
      def find_or_initialize_by_country_code(country_code)
        with_country_code(country_code.to_s).first || build(:country_code => country_code.to_s)
      end
    end
  end
end
