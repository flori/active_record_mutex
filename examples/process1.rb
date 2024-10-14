# process1.rb

require 'active_record_mutex'

database_url = URI.parse(ENV.fetch('DATABASE_URL'))
database = File.basename(database_url.path)
database_url_without_db = database_url.dup.tap { _1.path = '' }
ch = ActiveRecord::Base.establish_connection(database_url_without_db.to_s)
ch.with_connection { _1.execute %{ CREATE DATABASE IF NOT EXISTS #{database} } }
ActiveRecord::Base.establish_connection(database_url.to_s)

mutex = ActiveRecord::DatabaseMutex.for('my_mutex')

lock_result1 = mutex.lock(timeout: 5)
puts "Process 1: Lock acquired (first): #{lock_result1}"

puts "Process 1: Waiting for 10s"
sleep(10)

lock_result2 = mutex.lock(timeout: 5)
puts "Process 1: Lock acquired (second): #{lock_result2}"

mutex.unlock # first
mutex.unlock # second

puts "Process 1: Unlocked the mutex twice"

puts "Process 1: Waiting for 10s"
sleep(10)

puts "Process 1: Exiting"
