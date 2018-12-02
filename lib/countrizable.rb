require "countrizable/railtie"
require 'request_store'
require 'active_record'
require 'patches/active_record/xml_attribute_serializer'
require 'patches/active_record/query_method'
require 'patches/active_record/relation'
require 'patches/active_record/serialization'
require 'patches/active_record/uniqueness_validator'
require 'patches/active_record/persistence'

module Countrizable
  autoload :ActiveRecord, 'countrizable/active_record'
  autoload :Interpolation,   'countrizable/interpolation'

  class << self
    def country_code
      read_country_code || 'es'
    end

    def country_code=(country_code)
      set_country_code(country_code)
    end

    def with_country_code(country_code, &block)
      previous_country_code = read_country_code
      begin
        set_country_code(country_code)
        result = yield(country_code)
      ensure
        set_country_code(previous_country_code)
      end
      result
    end

    def with_country_codes(*country_codes, &block)
      country_codes.flatten.map do |country_code|
        with_country_code(country_code, &block)
      end
    end

    def fallbacks=(country_codes)
      set_fallbacks(country_codes)
    end

    def fallbacks(for_country_code = self.country_code)
      read_fallbacks[for_country_code] || default_fallbacks(for_country_code)
    end

    def default_fallbacks(for_country_code = self.country_code)
      [for_country_code.to_sym]
    end

    # Thread-safe global storage
    def storage
      RequestStore.store
    end

    def rails_5?
      ::ActiveRecord.version >= Gem::Version.new('5.1.0')
    end

    def rails_52?
      ::ActiveRecord.version >= Gem::Version.new('5.2.0')
    end

  protected

    def read_country_code
      storage[:countrizable_country_code]
    end

    def set_country_code(country_code)
      storage[:countrizable_country_code] = country_code.try(:to_sym)
    end

    def read_fallbacks
      storage[:countrizable_fallbacks] || HashWithIndifferentAccess.new
    end

    def set_fallbacks(country_codes)
      fallback_hash = HashWithIndifferentAccess.new

      country_codes.each do |key, value|
        fallback_hash[key] = value.presence || [key]
      end if country_codes.present?

      storage[:countrizable_country_code] = fallback_hash
    end
  end
end

ActiveRecord::Base.class_attribute :countrizable_serialized_attributes, instance_writer: false
ActiveRecord::Base.countrizable_serialized_attributes = {}

ActiveRecord::Base.extend(Countrizable::ActiveRecord::ActMacro)