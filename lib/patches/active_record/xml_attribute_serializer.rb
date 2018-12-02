begin
  require 'active_record/serializers/xml_serializer'
rescue LoadError
end

module Countrizable
  module XmlSerializer
    module Attribute
      def compute_type
        klass = @serializable.class
        if klass.country_attributes? && klass.country_attribute_names.include?(name.to_sym)
          :string
        else
          super
        end
      end
    end
  end
end

if defined?(ActiveRecord::XmlSerializer)
  ActiveRecord::XmlSerializer::Attribute.send(:prepend, Countrizable::XmlSerializer::Attribute)
end