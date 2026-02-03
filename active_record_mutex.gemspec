# -*- encoding: utf-8 -*-
# stub: active_record_mutex 3.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "active_record_mutex".freeze
  s.version = "3.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Florian Frank".freeze]
  s.date = "1980-01-02"
  s.description = "Mutex that can be used to synchronise ruby processes via an ActiveRecord datababase connection. (Only Mysql is supported at the moment.)".freeze
  s.email = "flori@ping.de".freeze
  s.extra_rdoc_files = ["README.md".freeze, "lib/active_record/database_mutex.rb".freeze, "lib/active_record/database_mutex/implementation.rb".freeze, "lib/active_record/database_mutex/version.rb".freeze, "lib/active_record/mutex.rb".freeze, "lib/active_record_mutex.rb".freeze]
  s.files = [".envrc".freeze, "CHANGES.md".freeze, "COPYING".freeze, "Gemfile".freeze, "README.md".freeze, "Rakefile".freeze, "active_record_mutex.gemspec".freeze, "docker-compose.yml".freeze, "examples/process1.rb".freeze, "examples/process2.rb".freeze, "lib/active_record/database_mutex.rb".freeze, "lib/active_record/database_mutex/implementation.rb".freeze, "lib/active_record/database_mutex/version.rb".freeze, "lib/active_record/mutex.rb".freeze, "lib/active_record_mutex.rb".freeze, "test/database_mutex_test.rb".freeze, "test/test_helper.rb".freeze]
  s.homepage = "http://github.com/flori/active_record_mutex".freeze
  s.licenses = ["GPL-2".freeze]
  s.rdoc_options = ["--title".freeze, "ActiveRecordMutex - Implementation of a Mutex for Active Record".freeze, "--main".freeze, "README.md".freeze]
  s.rubygems_version = "4.0.3".freeze
  s.summary = "Implementation of a Mutex for Active Record".freeze
  s.test_files = ["test/database_mutex_test.rb".freeze, "test/test_helper.rb".freeze]

  s.specification_version = 4

  s.add_development_dependency(%q<gem_hadar>.freeze, [">= 2.17.0".freeze])
  s.add_development_dependency(%q<all_images>.freeze, [">= 0.11.2".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<debug>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<mysql2>.freeze, ["~> 0.3".freeze])
  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 4.0".freeze])
  s.add_runtime_dependency(%q<ostruct>.freeze, ["~> 0.6".freeze])
end
