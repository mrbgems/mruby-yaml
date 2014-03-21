## mruby-yaml

#### YAML gem for [mruby](https://github.com/mruby/mruby)

mruby-yaml wraps [libyaml](http://pyyaml.org/wiki/LibYAML) and therefore complies with the YAML 1.1 standard. File IO is not supported, as this would create a dependency on other mruby gems.

### Documentation

#### `YAML.load(yaml_str)`
Converts a valid YAML 1.1 string to a Ruby object containing hashes, arrays, and strings. This currently attempts to convert YAML scalars (i.e. strings) to Fixnum, Float, Symbol, and Range primitives. All the rest is converted to String objects.

#### `YAML.dump(obj)`
Converts a Ruby object to a valid YAML 1.1 string. Arrays, Hashes, and their subclasses are represented as YAML sequences and mapping nodes. Other objects are converted to strings and represented as scalars.
