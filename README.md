## mruby-yaml

#### YAML gem for [mruby](https://github.com/mruby/mruby)

mruby-yaml wraps [libyaml](http://pyyaml.org/wiki/LibYAML) and therefore complies with the YAML 1.1 standard. File IO is automatically enabled if the `mruby-io` gem is available.

### Documentation

#### `YAML.load(yaml_str)`
Converts a valid YAML 1.1 string to a Ruby object containing hashes, arrays, and strings. This currently attempts to convert YAML scalars (i.e. strings) to Fixnum, Float, Symbol, and Range primitives. All the rest is converted to String objects.

#### `obj = File.open('data.yaml') {|f| YAML.load(f)}`
As above, but loads the YAML string from `data.yaml` into object `obj`.

#### `YAML.dump(obj)`
Converts a Ruby object to a valid YAML 1.1 string. Arrays, Hashes, and their subclasses are represented as YAML sequences and mapping nodes. Other objects are converted to strings and represented as scalars.

#### `File.open('data.yaml', 'w') {|f| YAML.dump(obj, f)}`
As above, but dumps the YAML string in `obj` into `data.yaml`.
