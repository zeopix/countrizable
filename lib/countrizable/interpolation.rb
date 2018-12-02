module Countrizable
  module Interpolation
    def interpolate(name, model, args)
      country_value = model.read_attribute(name, {:country_code => country_code_from(args)})
      try_interpolation country_value, interpolation_args_from(args)
    end

    private

    def interpolation_args_from(args)
      args.detect {|a| a.is_a? Hash }
    end

    def country_code_from(args)
      args.detect {|a| !a.is_a? Hash }
    end

    def try_interpolation(country_value,args)
      if args
        I18n.interpolate(country_value,args)
      else
        country_value
      end
    end

    extend self
  end
end
