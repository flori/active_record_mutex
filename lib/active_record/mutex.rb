require 'active_record'
require 'active_record/mutex/version'

module ActiveRecord
  # This module is mixed into ActiveRecord::Base to provide the mutex methods
  # that return a mutex for a particular ActiveRecord::Base subclass/instance.
  module Mutex
    # This is the base exception of all mutex exceptions.
    class MutexError < ActiveRecordError; end

    # This exception is raised if a mutex of the given name isn't locked at the
    # moment and unlock was called.
    class MutexUnlockFailed < MutexError; end

    # This exception is raised if a mutex of the given name is locked at the
    # moment and lock was called again.
    class MutexLocked < MutexError; end

    def self.included(modul)
      modul.instance_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      # Returns a mutex instance for this ActiveRecord subclass.
      def mutex
        @mutex ||= Mutex.new(:name => name)
      end
    end

    # Returns a mutex instance for this ActiveRecord instance.
    def mutex
      @mutex ||= Mutex.new(:name => self.class.name)
    end

    class Mutex
      # Creates a mutex with the name given with the option :name.
      def initialize(opts = {})
        @name = opts[:name] or raise ArgumentError, "Mutex requires a :name argument"
      end

      # Returns the name of this mutex as given as a constructor argument.
      attr_reader :name

      # Locks the mutex if it isn't already locked via another database
      # connection and yields to the given block. After executing the block's
      # content the mutex is unlocked (only if it was locked by this
      # synchronize method before).
      #
      # If the mutex was already locked by another database connection the
      # method blocks until it could aquire the lock and only then the block's
      # content is executed. If the mutex was already locked by the current database
      # connection then the block's content is run and the the mutex isn't
      # unlocked afterwards.
      #
      # If a value in seconds is passed to the :timeout option the blocking
      # ends after that many seconds and the method returns immediately if the
      # lock couldn't be aquired during that time.
      def synchronize(opts = {})
        locked_before = aquired_lock?
        lock opts
        yield
      rescue ActiveRecord::Mutex::MutexLocked
        return nil
      ensure
        locked_before or unlock
      end

      # Locks the mutex and returns true if successful. If the mutex is
      # already locked and the timeout in seconds is given as the :timeout
      # option, this method raises a MutexLocked exception after that many
      # seconds. If the :timeout option wasn't given, this method blocks until
      # the lock could be aquired.
      def lock(opts = {})
        if opts[:timeout]
          lock_with_timeout opts
        else
          begin
            lock_with_timeout :timeout => 1
          rescue MutexLocked
            retry
          end
        end
      end

      # Unlocks the mutex and returns true if successful. Otherwise this method
      # raises a MutexLocked exception.
      def unlock(*)
        case query("SELECT RELEASE_LOCK(#{ActiveRecord::Base.quote_value(name)})")
        when 1      then true
        when 0, nil then raise MutexUnlockFailed, "unlocking of mutex '#{name}' failed"
        end
      end

      # Returns true if this mutex is unlocked at the moment.
      def unlocked?
        query("SELECT IS_FREE_LOCK(#{ActiveRecord::Base.quote_value(name)})") == 1
      end

      # Returns true if this mutex is locked at the moment.
      def locked?
        not unlocked?
      end
 
      # Returns true if this mutex is locked by this database connection.
      def aquired_lock?
        query("SELECT CONNECTION_ID() = IS_USED_LOCK(#{ActiveRecord::Base.quote_value(name)})") == 1
      end

      # Returns true if this mutex is not locked by this database connection.
      def not_aquired_lock?
        not aquired_lock?
      end

      # Returns a string representation of this Mutex instance.
      def to_s
        "#<#{self.class} #{name}>"
      end

      alias inspect to_s

      private

      def lock_with_timeout(opts = {})
        timeout = opts[:timeout] || 1
        case query("SELECT GET_LOCK(#{ActiveRecord::Base.quote_value(name)}, #{timeout})")
        when 1 then true
        when 0 then raise MutexLocked, "mutex '#{name}' is already locked"
        end
      end

      def query(sql)
        if result = ActiveRecord::Base.connection.execute(sql)
          result = result.first.first.to_i
          $DEBUG and warn %{query("#{sql}") = #{result}}
        end
        result
      rescue ActiveRecord::StatementInvalid
        nil
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Mutex
end
