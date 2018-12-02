module Countrizable
  module ActiveRecord
    module AdapterDirty
      def write country_code, name, value
        # Dirty tracking, paraphrased from
        # ActiveRecord::AttributeMethods::Dirty#write_attribute.
        name = name.to_s
        store_old_value name, country_code
        old_values = dirty[name]
        old_value = old_values[country_code]
        is_changed = record.send :attribute_changed?, name
        if is_changed && value == old_value
          # If there's already a change, delete it if this undoes the change.
          old_values.delete country_code
          if old_values.empty?
            _reset_attribute name
          end
        elsif !is_changed
          # If there's not a change yet, record it.
          record.send(:attribute_will_change!, name) if old_value != value
        end

        super country_code, name, value
      end

      attr_writer :dirty
      def dirty
        @dirty ||= {}
      end

      def store_old_value name, country_code
        dirty[name] ||= {}
        unless dirty[name].key? country_code
          old = fetch(country_code, name)
          old = old.dup if old.duplicable?
          dirty[name][country_code] = old
        end
      end

      def clear_dirty
        self.dirty = {}
      end

      def _reset_attribute name
        record.send("#{name}=", record.changed_attributes[name])
        record.send(:clear_attribute_changes, [name])
      end

      def reset
        clear_dirty
        super
      end

    end
  end
end