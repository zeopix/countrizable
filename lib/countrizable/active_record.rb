module Countrizable
  module ActiveRecord
    autoload :ActMacro,                     'countrizable/active_record/act_macro'
    autoload :Adapter,                      'countrizable/active_record/adapter'
    autoload :AdapterDirty,                 'countrizable/active_record/adapter_dirty'
    autoload :Attributes,                   'countrizable/active_record/attributes'
    autoload :ClassMethods,                 'countrizable/active_record/class_methods'
    autoload :Exceptions,                   'countrizable/active_record/exceptions'
    autoload :InstanceMethods,              'countrizable/active_record/instance_methods'
    autoload :Migration,                    'countrizable/active_record/migration'
    autoload :CountryValue,                  'countrizable/active_record/country_value'
    autoload :CountryAttributesQuery,    'countrizable/active_record/country_attributes_query'
  end
end