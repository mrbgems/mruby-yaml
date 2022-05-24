MRuby::Gem::Specification.new('mruby-yaml') do |spec|
  spec.license = 'MIT'
  spec.authors = 'Andrew Belt'
  spec.version = '0.1.0'
  spec.description = 'YAML gem for mruby'
  spec.homepage = 'https://github.com/mrbgems/mruby-yaml'

  spec.linker.libraries << 'yaml'

  require 'open3'
  def run_command env, command
    STDOUT.sync = true
    puts "build: [exec] #{command}"
    Open3.popen2e(env, command) do |stdin, stdout, thread|
      print stdout.read
      fail "#{command} failed" if thread.value != 0
    end
  end

  use_system_library = ENV.fetch('MRUBY_YAML_USE_SYSTEM_LIBRARY', '') != ''

  unless use_system_library
    yaml_dir = File.join(build_dir, 'libyaml')
    yaml_base_dir = File.join(spec.dir, 'vendor', 'libyaml')

    FileUtils.mkdir_p build_dir

    # We build libyaml in the gem's build directory, which means
    # copying the sources from the repo.
    unless File.exist?(yaml_dir)
      # But first, we generate the configure script. This requires GNU
      # autoconf to be installed.
      Dir.chdir(yaml_base_dir) do
        run_command({}, './bootstrap')
      end

      FileUtils.cp_r(yaml_base_dir, build_dir)
    end

    unless File.exist?("#{yaml_dir}/build/lib/libyaml.a")
      Dir.chdir(yaml_dir) do
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
end
