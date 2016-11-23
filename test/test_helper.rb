if ENV['START_SIMPLECOV'].to_i == 1
  require 'simplecov'
  SimpleCov.start do
    add_filter "#{File.basename(File.dirname(__FILE__))}/"
  end
end

require 'active_record'
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
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
