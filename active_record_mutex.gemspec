# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "active_record_mutex"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Florian Frank"]
  s.date = "2012-05-07"
  s.description = "Mutex that can be used to synchronise ruby processes via an ActiveRecord datababase connection. (Only Mysql is supported at the moment.)"
  s.email = "flori@ping.de"
  s.extra_rdoc_files = ["README.rdoc", "lib/active_record_mutex.rb", "lib/active_record/mutex.rb", "lib/active_record/database_mutex.rb", "lib/active_record/database_mutex/version.rb", "lib/active_record/database_mutex/implementation.rb"]
  s.files = [".gitignore", "CHANGES", "Gemfile", "README.rdoc", "Rakefile", "VERSION", "active_record_mutex.gemspec", "lib/active_record/database_mutex.rb", "lib/active_record/database_mutex/implementation.rb", "lib/active_record/database_mutex/version.rb", "lib/active_record/mutex.rb", "lib/active_record_mutex.rb", "test/mutex_test.rb"]
  s.homepage = "http://github.com/flori/active_record_mutex"
  s.rdoc_options = ["--title", "ActiveRecordMutex - Implementation of a Mutex for Active Record", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Implementation of a Mutex for Active Record"
  s.test_files = ["test/mutex_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 0.0.12"])
      s.add_runtime_dependency(%q<mysql2>, ["~> 0.3.0"])
      s.add_runtime_dependency(%q<activerecord>, [">= 0"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 0.0.12"])
      s.add_dependency(%q<mysql2>, ["~> 0.3.0"])
      s.add_dependency(%q<activerecord>, [">= 0"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 0.0.12"])
    s.add_dependency(%q<mysql2>, ["~> 0.3.0"])
    s.add_dependency(%q<activerecord>, [">= 0"])
  end
end
