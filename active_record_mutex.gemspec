# -*- encoding: utf-8 -*-
# stub: active_record_mutex 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "active_record_mutex"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Florian Frank"]
  s.date = "2014-12-12"
  s.description = "Mutex that can be used to synchronise ruby processes via an ActiveRecord datababase connection. (Only Mysql is supported at the moment.)"
  s.email = "flori@ping.de"
  s.extra_rdoc_files = ["README.md", "lib/active_record/database_mutex.rb", "lib/active_record/database_mutex/implementation.rb", "lib/active_record/database_mutex/version.rb", "lib/active_record/mutex.rb", "lib/active_record_mutex.rb"]
  s.files = [".gitignore", ".travis.yml", "CHANGES", "COPYING", "Gemfile", "README.md", "Rakefile", "VERSION", "active_record_mutex.gemspec", "lib/active_record/database_mutex.rb", "lib/active_record/database_mutex/implementation.rb", "lib/active_record/database_mutex/version.rb", "lib/active_record/mutex.rb", "lib/active_record_mutex.rb", "test/database_mutex_test.rb", "test/test_helper.rb"]
  s.homepage = "http://github.com/flori/active_record_mutex"
  s.licenses = ["GPL-2"]
  s.rdoc_options = ["--title", "ActiveRecordMutex - Implementation of a Mutex for Active Record", "--main", "README.md"]
  s.rubygems_version = "2.4.4"
  s.summary = "Implementation of a Mutex for Active Record"
  s.test_files = ["test/database_mutex_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.3.2"])
      s.add_development_dependency(%q<test-unit>, ["~> 3.0"])
      s.add_development_dependency(%q<byebug>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_runtime_dependency(%q<mysql2>, ["~> 0.3.0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.3.2"])
      s.add_dependency(%q<test-unit>, ["~> 3.0"])
      s.add_dependency(%q<byebug>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<mysql2>, ["~> 0.3.0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.3.2"])
    s.add_dependency(%q<test-unit>, ["~> 3.0"])
    s.add_dependency(%q<byebug>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<mysql2>, ["~> 0.3.0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
  end
end
