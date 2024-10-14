if ENV['START_SIMPLECOV'].to_i == 1
  require 'simplecov'
  SimpleCov.start do
    add_filter "#{File.basename(File.dirname(__FILE__))}/"
  end
end

require 'active_record'
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'active_record/database_mutex'

def ec(**opts)
  ActiveRecord::Base.establish_connection(**opts).lease_connection
end

require 'debug'
database_url = URI.parse(ENV.fetch('DATABASE_URL'))
database = File.basename(database_url.path)
connection = ec(
  adapter:  database_url.scheme,
  username: database_url.user,
  password: database_url.password,
  host:     database_url.host,
  port:     database_url.port,
)
connection.execute %{ CREATE DATABASE IF NOT EXISTS #{database} }
connection = ec(
  adapter:  database_url.scheme,
  username: database_url.user,
  password: database_url.password,
  host:     database_url.host,
  port:     database_url.port,
  database:,
)
require 'test/unit'
