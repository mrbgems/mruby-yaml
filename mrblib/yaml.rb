module YAML
  # Only remap if IO gem is available
  if Object.const_defined? :IO then
    class << self
      alias dump_c dump
      alias load_c load
    end
  
    def YAML.load(arg)
      case arg
      when IO
        load_c arg.read
      when String
        load_c arg
      else
        raise ArgumentError, "Only Strings or IO objects"
      end
    end

    def YAML.dump(arg, file = nil)
      if (file && file.kind_of?(IO)) then
        file.write dump_c(arg)
      else
        dump_c arg
      end
    end
  end
end #module YAML

