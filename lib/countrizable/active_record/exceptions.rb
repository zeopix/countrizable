module Countrizable
  module ActiveRecord
    module Exceptions
      class MigrationError < StandardError; end

      class BadFieldName < MigrationError
        def initialize(field)
          super("Missing country valued field #{field.inspect}")
        end
      end
    end
  end
end