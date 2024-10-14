# process2.rb

require 'active_record_mutex'

database_url = URI.parse(ENV.fetch('DATABASE_URL'))
database = File.basename(database_url.path)
database_url_without_db = database_url.dup.tap { _1.path = '' }
ch = ActiveRecord::Base.establish_connection(database_url_without_db.to_s)
ch.with_connection { _1.execute %{ CREATE DATABASE IF NOT EXISTS #{database} } }
ActiveRecord::Base.establish_connection(database_url.to_s)

mutex = ActiveRecord::DatabaseMutex.for('my_mutex')

begin
  lock_result3 = mutex.lock(timeout: 5)
  puts "Process 2: Lock acquired (first): #{lock_result3}"
rescue ActiveRecord::DatabaseMutex::MutexLocked
  puts "Process 2: Mutex locked by another process, waiting..."
end

puts "Process 2: Waiting for 10s"
sleep(10)

puts "Process 2: Trying to lock again"
lock_result4 = mutex.lock(timeout: 5)
puts "Process 2: Lock acquired (second): #{lock_result4}"

puts "Process 2: Exiting"
