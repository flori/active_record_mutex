require 'test_helper'

class DatabaseMutexTest < Test::Unit::TestCase
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

  def test_class_method_mutex
    old, ENV['RAILS_ENV'] = ENV['RAILS_ENV'], nil
    Foo.instance_eval do
      @mutex = nil
    end
    mutex = Foo.mutex
    assert_kind_of ActiveRecord::DatabaseMutex::Implementation, mutex
    assert_equal Foo.name, mutex.name
  ensure
    ENV['RAILS_ENV'] = old
  end

  def test_class_method_mutex_within_env
    old, ENV['RAILS_ENV'] = ENV['RAILS_ENV'], 'test'
    Foo.instance_eval do
      @mutex = nil
    end
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

  def test_create
    mutex = Implementation.new(:name => 'Create')
    assert_equal 'Create', mutex.name
  end

  def test_lock
    mutex = Implementation.new(:name => 'Lock')
    assert mutex.unlocked?
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.aquired_lock?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.lock
    assert_equal 2, mutex.send(:counter_value)
  end

  def test_unlock
    mutex = Implementation.new(:name => 'Unlock')
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
    assert_equal 0, mutex.send(:counter_value)
    assert mutex.lock
    assert mutex.locked?
    assert mutex.aquired_lock?
    assert_equal 1, mutex.send(:counter_value)
    assert mutex.unlock
    assert mutex.unlocked?
    assert_equal 0, mutex.send(:counter_value)
    assert_raises(ActiveRecord::DatabaseMutex::MutexUnlockFailed) { mutex.unlock }
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

  def test_counter_name
    mutex = Implementation.new(:name => (250..255).map(&:chr) * '')
    assert_equal '@$_vv8.f7.', mutex.send(:counter)
  end
end
