# -*- encoding: utf-8 -*-
# stub: active_record_mutex 2.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "active_record_mutex".freeze
  s.version = "2.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "2016-11-23"
  s.description = "Mutex that can be used to synchronise ruby processes via an ActiveRecord datababase connection. (Only Mysql is supported at the moment.)".freeze
  s.email = "flori@ping.de".freeze
  s.extra_rdoc_files = ["README.md".freeze, "lib/active_record/database_mutex.rb".freeze, "lib/active_record/database_mutex/implementation.rb".freeze, "lib/active_record/database_mutex/version.rb".freeze, "lib/active_record/mutex.rb".freeze, "lib/active_record_mutex.rb".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "COPYING".freeze, "Gemfile".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "active_record_mutex.gemspec".freeze, "lib/active_record/database_mutex.rb".freeze, "lib/active_record/database_mutex/implementation.rb".freeze, "lib/active_record/database_mutex/version.rb".freeze, "lib/active_record/mutex.rb".freeze, "lib/active_record_mutex.rb".freeze, "test/database_mutex_test.rb".freeze, "test/test_helper.rb".freeze]
  s.homepage = "http://github.com/flori/active_record_mutex".freeze
  s.licenses = ["GPL-2".freeze]
  s.rdoc_options = ["--title".freeze, "ActiveRecordMutex - Implementation of a Mutex for Active Record".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "2.6.7".freeze
  s.summary = "Implementation of a Mutex for Active Record".freeze
  s.test_files = ["test/database_mutex_test.rb".freeze, "test/test_helper.rb".freeze]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>.freeze, ["~> 1.7.1"])
      s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<mysql2>.freeze, ["~> 0.3.0"])
      s.add_runtime_dependency(%q<activerecord>.freeze, ["~> 4.0"])
      s.add_runtime_dependency(%q<tins>.freeze, ["~> 1.12"])
    else
      s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.7.1"])
      s.add_dependency(%q<test-unit>.freeze, ["~> 3.0"])
      s.add_dependency(%q<byebug>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<mysql2>.freeze, ["~> 0.3.0"])
      s.add_dependency(%q<activerecord>.freeze, ["~> 4.0"])
      s.add_dependency(%q<tins>.freeze, ["~> 1.12"])
    end
  else
    s.add_dependency(%q<gem_hadar>.freeze, ["~> 1.7.1"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.0"])
    s.add_dependency(%q<byebug>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<mysql2>.freeze, ["~> 0.3.0"])
    s.add_dependency(%q<activerecord>.freeze, ["~> 4.0"])
    s.add_dependency(%q<tins>.freeze, ["~> 1.12"])
  end
end
