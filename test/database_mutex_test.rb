require 'test_helper'

class DatabaseMutexTest < Test::Unit::TestCase
  include ActiveRecord::DatabaseMutex

  class Foo < ActiveRecord::Base; end

  def setup
    Foo.instance_eval do
      @mutex_name = nil
      @mutex      = nil
    end
    ActiveRecord::Schema.define(:version => 1) do
      create_table(:foos, :force => true) { |t| t.string :bar }
    end
  end

  def teardown
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end

  def test_class_method_mutex
    old, ENV['RAILS_ENV'] = ENV['RAILS_ENV'], nil
    mutex = Foo.mutex
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
    assert_equal Foo.name, mutex.name
  ensure
    ENV['RAILS_ENV'] = old
  end

  def test_class_method_mutex_within_env
    old, ENV['RAILS_ENV'] = ENV['RAILS_ENV'], 'test'
    mutex = Foo.mutex
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
    assert_equal "#{Foo.name}@test", mutex.name
  ensure
    ENV['RAILS_ENV'] = old
  end

  def test_instance_method
    instance = Foo.new
    assert_raises(ActiveRecord::DatabaseMutex::MutexInvalidState) do
      instance.mutex
    end
    assert_equal true, instance.save
    mutex = instance.mutex
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
    assert_equal "#{instance.id}@#{Foo.name}", mutex.name
  end

  def test_factory_method_for
    mutex = ActiveRecord::DatabaseMutex.for('some_name')
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
  end

  private def lock_exists?(string)
    ActiveRecord::Base.all_mutexes.map(&:OBJECT_NAME).any? {
      _1.include?(string)
    }
  end

  def test_all_mutexes
    string = SecureRandom.hex(16)
    mutex = ActiveRecord::DatabaseMutex.for(string)
    assert_false lock_exists?(string)
    mutex.lock
    assert lock_exists?(string)
  ensure
    mutex.unlock force: true
  end

  def test_create
    mutex = Implementation.new(:name => 'Create')
    assert_equal 'Create', mutex.name
  end

  def test_lock
    mutex = Implementation.new(:name => 'Lock')
    assert mutex.unlocked?
    assert mutex.not_owned?
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.lock
    assert_equal 2, mutex.send(:counter_value)
  end

  def test_lock_with_timeout_multiple_threads
    done = false
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Implementation.new(:name => 'LockTimeout').synchronize {
          done = true
          sleep 2
        }
      end
    ensure
      done = true
    end
    mutex = Implementation.new(:name => 'LockTimeout')
    until done
      sleep 0.1
    end
    assert_false mutex.lock(timeout: 0.1, raise: false)
    assert_raises(ActiveRecord::DatabaseMutex::MutexLocked) { mutex.lock(timeout: 0.1) }
    thread.join
    assert mutex.unlocked?
    assert_false mutex.owned?
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock(timeout: 1)
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 1, mutex.send(:counter_value)
  end

  def test_lock_without_timeout_multiple_threads
    done = false
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Implementation.new(:name => 'SpinTimeout').synchronize {
          done = true
          sleep 2
        }
      end
    ensure
      done = true
    end
    mutex = Implementation.new(:name => 'SpinTimeout')
    until done
      sleep 0.1
    end
    thread.join
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 1, mutex.send(:counter_value)
  end

  def test_unlock
    mutex = Implementation.new(:name => 'Unlock')
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 2, mutex.send(:counter_value)
    assert_false mutex.unlock
    assert_false mutex.unlocked?
    assert_false mutex.not_owned?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.unlock
    assert mutex.unlocked?
    assert mutex.not_owned?
    assert_equal 0, mutex.send(:counter_value)
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
  end

  def test_unlock_with_force
    mutex = Implementation.new(:name => 'Unlock')
    assert_false mutex.unlock raise: false
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 2, mutex.send(:counter_value)
    assert mutex.unlock force: true
    assert mutex.unlocked?
    assert mutex.not_owned?
    assert_equal 0, mutex.send(:counter_value)
    assert_false mutex.unlock force: true, raise: false
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock force: true }
  end

  def test_unlock?
    mutex = Implementation.new(:name => 'Unlock')
    assert_nil mutex.unlock?
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.owned?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.unlock?
    assert mutex.unlocked?
    assert mutex.not_owned?
    assert_equal 0, mutex.send(:counter_value)
    assert_nil mutex.unlock?
  end

  def test_synchronize
    mutex = Implementation.new(:name => 'Sync1')
    assert mutex.unlocked?
    assert_equal 0, mutex.send(:counter_value)
    mutex.synchronize do
      assert mutex.locked?
      assert_equal 1, mutex.send(:counter_value)
    end
    assert mutex.unlocked?
    assert_equal 0, mutex.send(:counter_value)
  end

  def test_synchronize_two_threads
    done = false
    thread = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Implementation.new(:name => 'Sync1').synchronize {
          done = true
          sleep 2
        }
      end
    ensure
      done = true
    end
    mutex = Implementation.new(:name => 'Sync1')
    yielded = false
    until done
      sleep 0.1
    end
    mutex.synchronize(block: false) { yielded  = true }
    assert_false yielded
    thread.join
    mutex.synchronize(block: false) { yielded  = true }
    assert yielded
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
    assert mutex.send(:counter_zero?)
    assert_equal 0, mutex.send(:counter_value)
    mutex.synchronize do
      assert mutex.locked?
      assert !mutex.send(:counter_zero?)
      assert_equal 1, mutex.send(:counter_value)
      mutex.synchronize do
        assert mutex.locked?
        assert !mutex.send(:counter_zero?)
        assert_equal 2, mutex.send(:counter_value)
      end
      assert mutex.locked?
      assert !mutex.send(:counter_zero?)
      assert_equal 1, mutex.send(:counter_value)
    end
    assert mutex.unlocked?
    assert mutex.send(:counter_zero?)
    assert_equal 0, mutex.send(:counter_value)
  end

  def test_synchronize_already_locked
    mutex = Implementation.new(:name => 'Sync4')
    def mutex.lock(*)
      raise ActiveRecord::DatabaseMutex::MutexLocked
    end
    assert_nil mutex.synchronize {}
  end

  def test_internal_name
    mutex = Implementation.new(:name => (250..255).map(&:chr) * '')
    assert_equal '$3i3xQvUrNPGyH6kaIOkiPw', mutex.send(:internal_name)
  end

  def test_counter_name
    mutex = Implementation.new(:name => (250..255).map(&:chr) * '')
    assert_equal '@$3i3xQvUrNPGyH6kaIOkiPw', mutex.send(:counter)
  end
end
