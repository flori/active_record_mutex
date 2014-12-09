$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'active_record'
require 'active_record/database_mutex'

ActiveRecord::Base.establish_connection(
  :adapter  => "mysql2",
  :database => ENV['DATABASE'] || "test",
  :username => ENV['USER'],
  :password => ENV['PASSWORD'],
  :host     => ENV['HOST'] || 'localhost'
)
require 'test/unit'
require 'byebug'
