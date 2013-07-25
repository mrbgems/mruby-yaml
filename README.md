## mruby-yaml

#### YAML gem for [mruby](https://github.com/mruby/mruby)

mruby-yaml wraps [libyaml](http://pyyaml.org/wiki/LibYAML) and therefore complies with the YAML 1.1 standard. File IO is not supported, as this would create a dependency on other mruby gems.

### Documentation

#### `YAML.load(yaml_str)` [TODO]
Converts a valid YAML 1.1 string to a Ruby object containing hashes, arrays, and strings. This currently does not attempt to convert YAML scalars (i.e. strings) to Integers and other primitives.

#### `YAML.dump(obj)` [TODO]
Converts a Ruby object to a valid YAML 1.1 string. Arrays, Hashes, and their subclasses are represented as YAML sequences and mapping nodes. Other objects are converted to strings and represented as scalars.