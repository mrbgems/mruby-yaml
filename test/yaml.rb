
# YAML::load

assert('YAML load scalar') do
	YAML.load('foo') == 'foo'
end

assert('YAML load fixnum') do
	YAML.load('5') == 5
end

assert('YAML load float') do
	YAML.load('5.5') == 5.5
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
	actual = YAML.load("foo: [1, 2.2, 300]\nbar: baz")
	expected = {'foo' => [1, 2.2, 300], 'bar' => 'baz'}
	actual == expected
end

assert('YAML load multi-byte') do
	actual = YAML.load("bar: ばー\nfoo: ふー")
	expected = {'foo' => 'ふー', 'bar' => 'ばー'}
	actual == expected
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
	expected = {'foo' => [1, 2, 3], 'bar' => 'baz'}
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end

assert('YAML dump multi-byte') do
	expected = {'foo' => 'ふー', 'bar' => 'ばー'}
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end
