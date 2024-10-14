if ENV['START_SIMPLECOV'].to_i == 1
  require 'simplecov'
  SimpleCov.start do
    add_filter "#{File.basename(File.dirname(__FILE__))}/"
  end
end

require 'active_record'
require 'active_record/database_mutex'
require 'debug'

database_url = URI.parse(ENV.fetch('DATABASE_URL'))
database = File.basename(database_url.path)
database_url_without_db = database_url.dup.tap { _1.path = '' }
ch = ActiveRecord::Base.establish_connection(database_url_without_db.to_s)
ch.with_connection { _1.execute %{ CREATE DATABASE IF NOT EXISTS #{database} } }
$ch = ActiveRecord::Base.establish_connection(database_url.to_s)

require 'test/unit'
