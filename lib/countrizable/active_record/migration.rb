require 'digest/sha1'

module Countrizable
  module ActiveRecord
    module Migration
      def countrizable_migrator
        @countrizable_migrator ||= Migrator.new(self)
      end

      delegate :create_country_value_table!, :add_country_value_fields!,
        :drop_country_value_table!, :country_value_index_name,
        :country_value_country_code_index_name, :to => :countrizable_migrator

      class Migrator
        include Countrizable::ActiveRecord::Exceptions

        attr_reader :model
        delegate :country_attribute_names, :connection, :table_name,
          :table_name_prefix, :country_values_table_name, :columns, :to => :model

        def initialize(model)
          @model = model
        end

        def fields
          @fields ||= complete_country_fields
        end

        def create_country_value_table!(fields = {}, options = {})
          extra = options.keys - [:migrate_data, :remove_source_columns, :unique_index]
          if extra.any?
            raise ArgumentError, "Unknown migration #{'option'.pluralize(extra.size)}: #{extra}"
          end
          @fields = fields
          # If we have fields we only want to create the country table with those fields
          complete_country_fields if fields.blank?
          validate_country_fields

          create_country_value_table
          add_country_value_fields!(fields, options)
          create_country_values_index(options)
          clear_schema_cache!
        end

        def add_country_value_fields!(fields, options = {})
          @fields = fields
          validate_country_fields
          add_country_value_fields
          clear_schema_cache!
          move_data_to_country_table if options[:migrate_data]
          remove_source_columns if options[:remove_source_columns]
          clear_schema_cache!
        end

        def remove_source_columns
          column_names = *fields.keys
          column_names.each do |column|
            if connection.column_exists?(table_name, column)
              connection.remove_column(table_name, column)
            end
          end
        end

        def drop_country_table!(options = {})
          move_data_to_model_table if options[:migrate_data]
          drop_country_values_index
          drop_country_value_table
          clear_schema_cache!
        end

        # This adds all the current country attributes of the model
        # It's a problem because in early migrations would add all the country attributes
        def complete_country_fields
          country_attribute_names.each do |name|
            @fields[name] ||= column_type(name)
          end
        end

        def create_country_value_table
          connection.create_table(country_values_table_name) do |t|
            t.references table_name.sub(/^#{table_name_prefix}/, '').singularize, :null => false, :index => false, :type => column_type(model.primary_key).to_sym
            t.string :country_code, :null => false
            t.timestamps :null => false
          end
        end

        def add_country_value_fields
          connection.change_table(country_values_table_name) do |t|
            fields.each do |name, options|
              if options.is_a? Hash
                t.column name, options.delete(:type), options
              else
                t.column name, options
              end
            end
          end
        end

        def create_country_values_index(options)
          foreign_key = "#{table_name.sub(/^#{table_name_prefix}/, "").singularize}_id".to_sym
          connection.add_index(
            country_values_table_name,
            foreign_key,
            :name => country_value_index_name
          )
          # index for select('DISTINCT country_code') call in country_value.rb
          connection.add_index(
            country_values_table_name,
            :country_code,
            :name => country_value_country_code_index_name
          )

          if options[:unique_index]
            connection.add_index(
              country_values_table_name,
              [foreign_key, :country_code],
              :name => country_value_unique_index_name,
              unique: true
            )
          end
        end

        def drop_country_value_table
          connection.drop_table(country_values_table_name)
        end

        def drop_country_values_index
          if connection.indexes(country_values_table_name).map(&:name).include?(country_value_index_name)
            connection.remove_index(country_values_table_name, :name => country_value_index_name)
          end
          if connection.indexes(country_values_table_name).map(&:name).include?(country_value_country_code_index_name)
            connection.remove_index(country_values_table_name, :name => country_value_country_code_index_name)
          end
        end

        def move_data_to_country_value_table
          model.find_each do |record|
            country_value = record.country_value_for(I18n.country_code) || record.country_values.build(:country_code => I18n.country_code)
            fields.each do |attribute_name, attribute_type|
              country_value[attribute_name] = record.read_attribute(attribute_name, {:country_attributed => false})
            end
            country_value.save!
          end
        end

        def move_data_to_model_table
          add_missing_columns

          # Find all of the country attributes for all records in the model.
          all_country_attributes = model.all.collect{|m| m.attributes}
          all_country_attributes.each do |country_record|
            # Create a hash containing the country column names and their values.
            country_attribute_names.inject(fields_to_update={}) do |f, name|
              f.update({name.to_sym => country_record[name.to_s]})
            end

            # Now, update the actual model's record with the hash.
            model.where(model.primary_key.to_sym => country_record[model.primary_key]).update_all(fields_to_update)
          end
        end

        def validate_country_fields
          fields.each do |name, options|
            raise BadFieldName.new(name) unless valid_field_name?(name)
          end
        end

        def column_type(name)
          columns.detect { |c| c.name == name.to_s }.try(:type) || :string
        end

        def valid_field_name?(name)
          country_attribute_names.include?(name)
        end

        def country_value_index_name
          truncate_index_name "index_#{country_values_table_name}_on_#{table_name.singularize}_id"
        end

        def country_value_country_code_index_name
          truncate_index_name "index_#{country_values_table_name}_on_country_code"
        end

        def country_value_unique_index_name
          truncate_index_name "index_#{country_values_table_name}_on_#{table_name.singularize}_id_and_country_code"
        end

        def clear_schema_cache!
          connection.schema_cache.clear! if connection.respond_to? :schema_cache
          model::CountryValue.reset_column_information
          model.reset_column_information
        end

        private

        def truncate_index_name(index_name)
          if index_name.size < connection.index_name_length
            index_name
          else
            "index_#{Digest::SHA1.hexdigest(index_name)}"[0, connection.index_name_length]
          end
        end

        def add_missing_columns
          clear_schema_cache!
          country_attribute_names.map(&:to_s).each do |attribute|
            unless model.column_names.include?(attribute)
              connection.add_column(table_name, attribute, model::CountryValue.columns_hash[attribute].type)
            end
          end
        end
      end
    end
  end
end