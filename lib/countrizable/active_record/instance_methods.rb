module Countrizable
  module ActiveRecord
    module InstanceMethods
      delegate :values_country_codes, :to => :country_values

      def countrizable
        @countrizable ||= Adapter.new(self)
      end

      def attributes
        super.merge(country_attributed_attributes)
      end

      def attributes=(new_attributes, *options)
        super unless new_attributes.respond_to?(:stringify_keys) && new_attributes.present?
        attributes = new_attributes.stringify_keys
        with_given_country_code(attributes) { super(attributes.except("country_code"), *options) }
      end

      if Countrizable.rails_52?

        # In Rails 5.2 we need to override *_assign_attributes* as it's called earlier
        # in the stack (before *assign_attributes*)
        # See https://github.com/rails/rails/blob/master/activerecord/lib/active_record/attribute_assignment.rb#L11
        def _assign_attributes(new_attributes)
          attributes = new_attributes.stringify_keys
          with_given_country_code(attributes) { super(attributes.except("country_code")) }
        end

      else

        def assign_attributes(new_attributes, *options)
          super unless new_attributes.respond_to?(:stringify_keys) && new_attributes.present?
          attributes = new_attributes.stringify_keys
          with_given_country_code(attributes) { super(attributes.except("country_code"), *options) }
        end

      end

      def write_attribute(name, value, *args, &block)
        return super(name, value, *args, &block) unless country_attributed?(name)

        options = {:country_code => Countrizable.country_code}.merge(args.first || {})

        countrizable.write(options[:country_code], name, value)
      end

      def [](attr_name)
        if country_attributed?(attr_name)
          read_attribute(attr_name)
        else
          read_attribute(attr_name) { |n| missing_attribute(n, caller) }
        end
      end

      def read_attribute(attr_name, options = {}, &block)
        name = if self.class.attribute_alias?(attr_name)
                 self.class.attribute_alias(attr_name).to_s
               else
                 attr_name.to_s
               end

        name = self.class.primary_key if name == "id".freeze && self.class.primary_key

        _read_attribute(name, options, &block)
      end

      def _read_attribute(attr_name, options = {}, &block)
        country_value = read_country_attribute(attr_name, options, &block)
        country_value.nil? ? super(attr_name, &block) : country_value
      end

      def attribute_names
        country_attribute_names.map(&:to_s) + super
      end

      delegate :country_attributed?, :to => :class

      def country_attributed_attributes
        country_attribute_names.inject({}) do |attributes, name|
          attributes.merge(name.to_s => send(name))
        end
      end

      # This method is basically the method built into Rails
      # but we have to pass {:country_attributed => false}
      def uncountry_attributes
        attribute_names.inject({}) do |attrs, name|
          attrs[name] = read_attribute(name, {:country_attributed => false}); attrs
        end
      end

      def set_country_values(options)
        options.keys.each do |country_code|
          country_value = country_value_for(country_code) ||
                        country_values.build(:country_code => country_code.to_s)

          options[country_code].each do |key, value|
            country_value.send :"#{key}=", value
            country_value.countrizable_model.send :"#{key}=", value
          end
          country_value.save if persisted?
        end
        countrizable.reset
      end

      def reload(options = nil)
        country_value_caches.clear
        country_attribute_names.each { |name| @attributes.reset(name.to_s) }
        countrizable.reset
        super(options)
      end

      def initialize_dup(other)
        @countrizable = nil
        @country_value_caches = nil
        super
        other.each_country_code_and_country_attribute do |country_code, name|
          countrizable.write(country_code, name, other.countrizable.fetch(country_code, name) )
        end
      end

      def country_value
        country_value_for(::Countrizable.country_code)
      end

      def country_value_for(country_code, build_if_missing = true)
        unless country_value_caches[country_code]
          # Fetch values from database as those in the country values collection may be incomplete
          _country_value = country_values.detect{|t| t.country_code.to_s == country_code.to_s}
          _country_value ||= country_values.with_country_code(country_code).first unless country_values.loaded?
          _country_value ||= country_values.build(:country_code => country_code) if build_if_missing
          country_value_caches[country_code] = _country_value if _country_value
        end
        country_value_caches[country_code]
      end

      def country_value_caches
        @country_value_caches ||= {}
      end

      def country_values_by_country_code
        country_values.each_with_object(HashWithIndifferentAccess.new) do |t, hash|
          hash[t.country_code] = block_given? ? yield(t) : t
        end
      end

      def country_attribute_by_country_code(name)
        country_values_by_country_code(&:"#{name}")
      end

      # Get available country_codes from country_value association, without a separate distinct query
      def available_country_codes
        country_values.map(&:country_code).uniq
      end

      def countrizable_fallbacks(country_code)
        Countrizable.fallbacks(country_code)
      end

      def save(*)
        result = Countrizable.with_country_code(country_value.country_code || I18n.default_country_code) do
          without_fallbacks do
            super
          end
        end
        if result
          countrizable.clear_dirty
        end

        result
      end

      def column_for_attribute name
        return super if country_attribute_names.exclude?(name)

        countrizable.send(:column_for_attribute, name)
      end

      def cache_key
        [super, country_value.cache_key].join("/")
      end

      def changed?
        changed_attributes.present? || country_values.any?(&:changed?)
      end

      # need to access instance variable directly since changed_attributes
      # is frozen as of Rails 4.2
      def original_changed_attributes
        @changed_attributes
      end

    protected

      def each_country_code_and_country_attribute
        used_country_codes.each do |country_code|
          country_attribute_names.each do |name|
            yield country_code, name
          end
        end
      end

      def used_country_codes
        country_codes = countrizable.stash.keys.concat(countrizable.stash.keys).concat(country_values.valued_country_codes)
        country_codes.uniq!
        country_codes
      end

      def save_country_values!
        countrizable.save_country_values!
        country_value_caches.clear
      end

      def with_given_country_code(_attributes, &block)
        attributes = _attributes.stringify_keys

        if country_code = attributes.try(:delete, "country_code")
          Countrizable.with_country_code(country_code, &block)
        else
          yield
        end
      end

      def without_fallbacks
        before = self.fallbacks_for_empty_country_values
        self.fallbacks_for_empty_country_values = false
        yield
      ensure
        self.fallbacks_for_empty_country_values = before
      end

      # nil or value
      def read_country_attribute(name, options)
        options = {:country_attributed => true, :country_code => nil}.merge(options) #:translated => true
        return nil unless options[:country_attributed] #translated
        return nil unless country_attributed?(name)

        value = countrizable.fetch(options[:country_code] || Countrizable.country_code, name)
        return nil if value.nil?

        block_given? ? yield(value) : value
      end
    end
  end
end