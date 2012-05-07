require 'test/unit'
require 'rubygems'

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

class MutexTest < Test::Unit::TestCase
  include ActiveRecord::DatabaseMutex

  class Foo < ActiveRecord::Base; end

  def setup
    ActiveRecord::Schema.define(:version => 1) do
      create_table(:foos, :force => true) { |t| t.string :bar }
    end
  end

  def teardown
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  def test_exported_methods
    mutex = Foo.mutex
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
    assert_equal mutex.name, Foo.name
    mutex = Foo.new.mutex
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
    assert_equal mutex.name, Foo.name
  end

  def test_create
    mutex = Implementation.new(:name => 'Create')
    assert_equal 'Create', mutex.name
  end

  def test_lock
    mutex = Implementation.new(:name => 'Lock')
    assert mutex.unlocked?
    assert mutex.lock
    assert mutex.locked?
    assert mutex.aquired_lock?
    assert mutex.lock
  end

  def test_unlock
    mutex = Implementation.new(:name => 'Unlock')
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
    assert mutex.lock
    assert mutex.locked?
    assert mutex.aquired_lock?
    assert mutex.unlock
    assert mutex.unlocked?
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
  end

  def test_synchronize
    mutex = Implementation.new(:name => 'Sync1')
    assert mutex.unlocked?
    mutex.synchronize do
      assert mutex.locked?
    end
    assert mutex.unlocked?
  end

  def test_synchronize_exception
    mutex = Implementation.new(:name => 'Sync2')
    exception = Class.new StandardError
    begin
      assert mutex.unlocked?
      mutex.synchronize do
        assert mutex.locked?
        raise exception
      end
    rescue exception
      assert mutex.unlocked?
      assert mutex.lock
      assert mutex.locked?
    end
  end

  def test_synchronize_nested
    mutex = Implementation.new(:name => 'Sync3')
    assert mutex.unlocked?
    mutex.synchronize do
      assert mutex.locked?
      mutex.synchronize do
        assert mutex.locked?
      end
      assert mutex.locked?
    end
    assert mutex.unlocked?
  end
end
