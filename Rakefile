begin
  require 'rake/gempackagetask'
rescue LoadError
end
require 'rake/clean'
require 'rbconfig'
include Config

PKG_NAME         = 'active_record_mutex'
PKG_VERSION      = File.read('VERSION').chomp
PKG_FILES        = FileList['**/*'].exclude(/^(doc|CVS|pkg|coverage)/)
PKG_SUMMARY      = 'Implementation of a Mutex for Active Record'
PKG_RDOC_OPTIONS = [ '--main', 'README', '--title', PKG_SUMMARY ]
CLEAN.include 'coverage', 'doc'

desc "Testing library"
task :test  do
  ruby %{-Ilib test/mutex_test.rb}
end

desc "Testing library (with coverage)"
task :coverage  do
  sh %{rcov -Ilib test/mutex_test.rb}
end

desc "Installing library"
task :install  do
  ruby 'install.rb'
end

desc "Creating documentation"
task :doc do
  sh 'rdoc', *(PKG_RDOC_OPTIONS + Dir['lib/**/*.rb']  + [ 'README' ])
end

if defined? Gem
  spec = Gem::Specification.new do |s|
    s.name         = PKG_NAME
    s.version      = PKG_VERSION
    s.summary      = PKG_SUMMARY
    s.description  = "Mutex that can be used to synchronise ruby processes via an ActiveRecord"\
      " datababase connection. (Only Mysql is supported at the moment.)"

    s.files        = PKG_FILES.to_a.sort

    s.require_path = 'lib'

    s.has_rdoc     = true
    s.rdoc_options = PKG_RDOC_OPTIONS
    s.extra_rdoc_files << 'README'
    #s.test_files << 'test/mutex_test.rb'

    s.author            = "Florian Frank"
    s.email             = "flori@ping.de"
    s.homepage          = "http://flori.github.com/#{PKG_NAME}"
    s.rubyforge_project = "#{PKG_NAME}"
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar      = true
    pkg.package_files += PKG_FILES
  end
end

desc m = "Writing version information for #{PKG_VERSION}"
task :version do
  puts m
  File.open(File.join('lib', 'active_record', 'mutex', 'version.rb'), 'w') do |v|
    v.puts <<EOT
module ActiveRecord
  module Mutex
    # ActiveRecord::Mutex version
    VERSION       = '#{PKG_VERSION}'
    VERSION_ARRAY = VERSION.split(/\\./).map { |x| x.to_i } # :nodoc:
    VERSION_MAJOR = VERSION_ARRAY[0] # :nodoc:
    VERSION_MINOR = VERSION_ARRAY[1] # :nodoc:
    VERSION_BUILD = VERSION_ARRAY[2] # :nodoc:
  end
end
EOT
  end
end

task :default => [ :version, :test ]

task :release => [ :clean, :version, :package ]
