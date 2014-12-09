# vim: set filetype=ruby et sw=2 ts=2:

require 'gem_hadar'

GemHadar do
  name        'active_record_mutex'
  path_name   'active_record/database_mutex'
  author      'Florian Frank'
  email       'flori@ping.de'
  homepage    "http://github.com/flori/#{name}"
  summary     'Implementation of a Mutex for Active Record'
  description  'Mutex that can be used to synchronise ruby processes via an ActiveRecord'\
               ' datababase connection. (Only Mysql is supported at the moment.)'
  test_dir    'test'
  ignore      '.*.sw[pon]', 'pkg', 'Gemfile.lock'
  readme      'README.rdoc'

  dependency  'mysql2', '~>0.3.0'
  dependency  'activerecord'
  development_dependency 'test-unit', '~>3.0'
  development_dependency 'byebug'
end
