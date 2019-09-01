
# YAML::load

assert('YAML load empty') do
	YAML.load('') == nil
end

assert('YAML load true') do
	assert_true YAML.load('true')
	assert_true YAML.load('True')
	assert_true YAML.load('TRUE')
	if YAML::SUPPORT_BOOLEAN_YES
		assert_true YAML.load('yes')
		assert_true YAML.load('Yes')
		assert_true YAML.load('YES')
	end
	if YAML::SUPPORT_BOOLEAN_ON
		assert_true YAML.load('on')
		assert_true YAML.load('On')
		assert_true YAML.load('ON')
	end
	if YAML::SUPPORT_BOOLEAN_SHORTHAND_YES
		assert_true YAML.load('y')
		assert_true YAML.load('Y')
	end
	true
end

assert('YAML load false') do
	assert_false YAML.load('false')
	assert_false YAML.load('False')
	assert_false YAML.load('FALSE')
	if YAML::SUPPORT_BOOLEAN_OFF
		assert_false YAML.load('off')
		assert_false YAML.load('Off')
		assert_false YAML.load('OFF')
	end
	if YAML::SUPPORT_BOOLEAN_NO
		assert_false YAML.load('no')
		assert_false YAML.load('NO')
	end
	if YAML::SUPPORT_BOOLEAN_SHORTHAND_NO
		assert_false YAML.load('n')
		assert_false YAML.load('N')
	end
	true
end

assert('YAML load null') do
	assert_equal nil, YAML.load('nil')
	assert_equal nil, YAML.load('~')
	if YAML::SUPPORT_NULL
		assert_equal nil, YAML.load('null')
		assert_equal nil, YAML.load('Null')
		assert_equal nil, YAML.load('NULL')
	end
	true
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
short_no: n
))
        y_val = 'y'
        y_val = true if YAML::SUPPORT_BOOLEAN_SHORTHAND_YES
        n_val = 'n'
        n_val = false if YAML::SUPPORT_BOOLEAN_SHORTHAND_NO
	expected = { 'canonical' => y_val, 'answer' => false, 'logical' => true,
							 'option' => true, 'short_no' => n_val }
	assert_equal expected, actual
end if YAML::SUPPORT_BOOLEAN_NO && YAML::SUPPORT_BOOLEAN_YES &&
	YAML::SUPPORT_BOOLEAN_ON && YAML::SUPPORT_BOOLEAN_OFF

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
end if YAML::SUPPORT_NULL

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
end if YAML::SUPPORT_NULL

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
	expected = {
		'foo' => [1, 2, 3, nil, true],
		'bar' => 'baz',
		'harf' => false,
		nil => ""
	}
	actual = YAML.load(YAML.dump(expected))
	assert_equal expected, actual
end

assert('YAML dump multi-byte') do
	expected = {'foo' => 'ふー', 'bar' => 'ばー'}
	actual = YAML.load(YAML.dump(expected))
	actual == expected
end
