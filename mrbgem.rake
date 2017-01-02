MRuby::Gem::Specification.new('mruby-yaml') do |spec|
	spec.license = 'MIT'
	spec.authors = 'Andrew Belt'
	spec.version = '0.1.0'
	spec.description = 'YAML gem for mruby'
	spec.homepage = 'https://github.com/AndrewBelt/mruby-yaml'
	
	spec.cc.flags = "-std=c99"
	spec.linker.libraries << 'yaml'
end
