MRuby::Gem::Specification.new('mruby-yaml') do |spec|
	spec.license = 'MIT'
	spec.authors = 'Andrew Belt'
	spec.version = '0.1.0'
	spec.description = 'YAML gem for mruby'
	spec.homepage = 'https://github.com/AndrewBelt/mruby-yaml'
	
	spec.linker.libraries << 'yaml'
  require 'open3'

  yaml_version = "0.1.6"
  yaml_dir = "#{build_dir}/yaml-#{yaml_version}"

  def run_command env, command
    STDOUT.sync = true
    puts "build: [exec] #{command}"
    Open3.popen2e(env, command) do |stdin, stdout, thread|
      print stdout.read
      fail "#{command} failed" if thread.value != 0
    end
  end

  FileUtils.mkdir_p build_dir

  if ! File.exists? yaml_dir
    Dir.chdir(build_dir) do
      e = {}
      run_command e, "curl -L https://pyyaml.org/download/libyaml/yaml-#{yaml_version}.tar.gz | tar -xzv"
      run_command e, "mkdir #{yaml_dir}/build"
    end
  end

  if ! File.exists? "#{yaml_dir}/build/lib/libyaml.a"
    Dir.chdir yaml_dir do
      e = {
        'CC' => "#{spec.build.cc.command} #{spec.build.cc.flags.join(' ')}",
        'CXX' => "#{spec.build.cxx.command} #{spec.build.cxx.flags.join(' ')}",
        'LD' => "#{spec.build.linker.command} #{spec.build.linker.flags.join(' ')}",
        'AR' => spec.build.archiver.command,
        'PREFIX' => "#{yaml_dir}/build"
      }

      configure_opts = %w(--prefix=$PREFIX --enable-static --disable-shared)
      if build.kind_of?(MRuby::CrossBuild) && build.host_target && build.build_target
        configure_opts += %W(--host #{spec.build.host_target} --build #{spec.build.build_target})
        if %w(x86_64-w64-mingw32 i686-w64-mingw32).include?(build.host_target)
          e["CFLAGS"] = "-DYAML_DECLARE_STATIC"
          spec.cc.flags << "-DYAML_DECLARE_STATIC"
        end
        e['LD'] = "x86_64-w64-mingw32-ld #{spec.build.linker.flags.join(' ')}" if build.host_target == 'x86_64-w64-mingw32'
        e['LD'] = "i686-w64-mingw32-ld #{spec.build.linker.flags.join(' ')}" if build.host_target == 'i686-w64-mingw32'
      end
      run_command e, "./configure #{configure_opts.join(" ")}"
      run_command e, "make"
      run_command e, "make install"
    end
  end

  spec.cc.include_paths << "#{yaml_dir}/build/include"
  spec.linker.library_paths << "#{yaml_dir}/build/lib/"
end
