
# YAML::load

assert('YAML load empty') do
	YAML.load('') == nil
end

assert('YAML load true') do
	YAML.load('true') == true &&
	YAML.load('True') == true &&
	YAML.load('TRUE') == true &&
	YAML.load('yes') == true &&
	YAML.load('Yes') == true &&
	YAML.load('YES') == true &&
	YAML.load('on') == true &&
	YAML.load('On') == true &&
	YAML.load('ON') == true &&
	YAML.load('y') == true &&
	YAML.load('Y') == true
end

assert('YAML load false') do
	YAML.load('false') == false &&
	YAML.load('False') == false &&
	YAML.load('FALSE') == false &&
	YAML.load('off') == false &&
	YAML.load('Off') == false &&
	YAML.load('OFF') == false &&
	YAML.load('no') == false &&
	YAML.load('NO') == false &&
	YAML.load('n') == false &&
	YAML.load('N') == false
end

assert('YAML load null') do
	YAML.load('nil') == nil &&
	YAML.load('null') == nil &&
	YAML.load('Null') == nil &&
	YAML.load('NULL') == nil &&
	YAML.load('~') == nil
end

assert('YAML load scalar') do
	YAML.load('foo') == 'foo'
end

assert('YAML load true as string') do
	YAML.load('"true"') == "true"
end

assert('YAML load false as string') do
	YAML.load('"false"') == "false"
end

assert('YAML load nil as string') do
	YAML.load('"nil"') == "nil"
end

assert('YAML load fixnum') do
	YAML.load('5') == 5
end

assert('YAML load fixnum as string') do
	YAML.load('"5"') == "5"
end

assert('YAML load float') do
	YAML.load('5.5') == 5.5
end

assert('YAML load float as string') do
	YAML.load('"5.5"') == "5.5"
end

assert('YAML load sequence') do
	YAML.load("- foo\n- bar\n- baz") == ['foo', 'bar', 'baz']
end

assert('YAML load mapping') do
	actual = YAML.load("foo: faz\nbar: baz")
	expected = {'foo' => 'faz', 'bar' => 'baz'}
	actual == expected
end

assert('YAML load combo') do
	actual = YAML.load("foo: [1, 2.2, 300, true, nil]\nbar: baz\nharf: false")
	expected = {'foo' => [1, 2.2, 300, true, nil], 'bar' => 'baz', 'harf' => false}
	actual == expected
end

assert('YAML load all') do
	actual = YAML.load("y: 1\nn: 2\nnull: 3\n~: 4")
	expected = { 'y' => 1, 'n' => 2, 'null' => 3, nil => 4 }
	assert_equal expected, actual
end

assert('YAML load multi-byte') do
	actual = YAML.load("bar: ばー\nfoo: ふー")
	expected = {'foo' => 'ふー', 'bar' => 'ばー'}
	actual == expected
end

# http://yaml.org/type/bool.html
assert('YAML boolean mapping') do
	actual = YAML.load(%(---
canonical: y
answer: NO
logical: True
option: on
))
	expected = { 'canonical' => true, 'answer' => false, 'logical' => true,
							 'option' => true }
	assert_equal expected, actual
end

# http://yaml.org/type/null.html
assert('YAML load empty document') do
	YAML.load('---') == nil
end

assert('YAML null mapping') do
	actual = YAML.load(%(---
# This mapping has four keys,
# one has a value.
empty:
canonical: ~
english: null
~: null key
))
	expected = { 'empty' => nil, 'canonical' => nil,
							 'english' => nil, nil => 'null key' }
	assert_equal expected, actual
end

assert('YAML null sequence') do
	actual = YAML.load(%(---
# This sequence has five
# entries, two have values.
sparse:
  - ~
  - 2nd entry
  -
  - 4th entry
  - Null
 ))
	expected = { 'sparse' => [nil, '2nd entry', nil, '4th entry', nil] }
	assert_equal expected, actual
end

# YAML::dump

# Note: There are a number of possible valid strings which can be
# generated from a single Ruby object.
# So we can't check for string equality.
# We have to parse it back again and compare the Ruby objects instead.

assert('YAML dump scalar') do
	expected = 'foo'
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end

assert('YAML dump sequence') do
	expected = ['foo', 'bar', 'baz']
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end

assert('YAML dump mapping') do
	expected = {'foo' => 'faz', 'bar' => 'baz'}
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end

assert('YAML dump combo') do
	expected = { 'foo' => [1, 2, 3, nil, true], 'bar' => 'baz', 'harf' => false, nil => true }
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end

assert('YAML dump multi-byte') do
	expected = {'foo' => 'ふー', 'bar' => 'ばー'}
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end
