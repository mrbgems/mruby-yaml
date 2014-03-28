
# YAML::load

assert('load scalar') do
	YAML.load('foo') == 'foo'
end

assert('load fixnum') do
	YAML.load('5') == 5
end

assert('load float') do
	YAML.load('5.5') == 5.5
end

assert('load sequence') do
	YAML.load("- foo\n- bar\n- baz") == ['foo', 'bar', 'baz']
end

assert('load mapping') do
	actual = YAML.load("foo: faz\nbar: baz")
	expected = {'foo' => 'faz', 'bar' => 'baz'}
	actual == expected
end

assert('load combo') do
	actual = YAML.load("foo: [1, 2.2, 300]\nbar: baz")
	expected = {'foo' => [1, 2.2, 300], 'bar' => 'baz'}
	actual == expected
end

assert('load multi-byte') do
	actual = YAML.load("bar: ばー\nfoo: ふー")
	expected = {'foo' => 'ふー', 'bar' => 'ばー'}
	actual == expected
end


# YAML::dump

# Note: There are a number of possible valid strings which can be
# generated from a single Ruby object. Therefore, I must rely on the
# stability of the YAML emitter to produce consistent results, so
# false positives may occur.
# These tests will check that the YAML emitter is not fatally
# failing or producing entirely incorrect results.

assert('dump scalar') do
	YAML.dump('foo') == "--- foo\n...\n"
end

assert('dump sequence') do
	actual = YAML.dump(['foo', 'bar', 'baz'])
	expected = "---\n- foo\n- bar\n- baz\n...\n"
	actual == expected
end

assert('dump mapping') do
	actual = YAML.dump({'foo' => 'faz', 'bar' => 'baz'})
	expected = "---\nbar: baz\nfoo: faz\n...\n"
	actual == expected
end

assert('dump combo') do
	actual = YAML.dump({'foo' => ['1', '2', '3'], 'bar' => 'baz'})
	expected = "---\nbar: baz\nfoo:\n- 1\n- 2\n- 3\n...\n"
	actual == expected
end

assert('dump multi-byte') do
	actual = YAML.dump({'foo' => 'ふー', 'bar' => 'ばー'})
	
	# TODO
	# Why does this not work?
	# expected = "---\nbar: \"ばー\"\nfoo: \"ふー\"\n...\n"
	expected = "---\nbar: \"\\u3070\\u30FC\"\nfoo: \"\\u3075\\u30FC\"\n...\n"
	actual == expected
end
