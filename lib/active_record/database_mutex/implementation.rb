require 'digest/md5'

module ActiveRecord
  module DatabaseMutex
    class Implementation

      class << self

        # The db method returns an instance of ActiveRecord::Base.connection
        def db
          ActiveRecord::Base.connection
        end
      end

      # Creates a mutex with the name given with the option :name.
      def initialize(opts = {})
        @name = opts[:name] or raise ArgumentError, "mutex requires a :name argument"
        counter or raise ArgumentError, 'argument :name is too long'
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
        locked = lock(opts) or return
        yield
      rescue ActiveRecord::DatabaseMutex::MutexLocked
        return nil
      ensure
        locked and unlock
      end

      # Locks the mutex and returns true if successful. If the mutex is
      # already locked and the timeout in seconds is given as the :timeout
      # option, this method raises a MutexLocked exception after that many
      # seconds. If the :timeout option wasn't given, this method blocks until
      # the lock could be aquired. The :nonblock option can be used to return
      # immediately if the lock cannot be acquired without blocking. When using
      # the spinlock approach with spin_timeout, it will wait for that many
      # seconds before attempting to acquire the lock; if unsuccessful, it will
      # retry indefinitely.
      def lock(opts = {})
        if opts[:nonblock]
          begin
            lock_with_timeout timeout: 0
          rescue MutexLocked
            false # If non-blocking and unable to acquire lock, return false.
          end
        elsif opts[:timeout]
          lock_with_timeout opts
        else
          spin_timeout = opts[:spin_timeout] || 1
          begin
            lock_with_timeout timeout: spin_timeout
          rescue MutexLocked
            retry
          end
        end
      end

      # Unlocks the mutex and returns true if successful. Otherwise this method
      # raises a MutexLocked exception.
      def unlock(*)
        if aquired_lock?
          decrease_counter
          if counter_zero?
            case query("SELECT RELEASE_LOCK(#{quote(name)})")
            when 1
              true
            when 0, nil
              raise MutexUnlockFailed, "unlocking of mutex '#{name}' failed"
            end
          end
        else
          raise MutexUnlockFailed, "unlocking of mutex '#{name}' failed"
        end
      end

      # Unlock this mutex and return self if successful, otherwise (the mutex
      # was not locked) nil is returned.
      def unlock?(*a)
        unlock(*a)
        self
      rescue MutexUnlockFailed
        nil
      end

      # Returns true if this mutex is unlocked at the moment.
      def unlocked?
        query("SELECT IS_FREE_LOCK(#{quote(name)})") == 1
      end

      # Returns true if this mutex is locked at the moment.
      def locked?
        not unlocked?
      end

      # Returns true if this mutex is locked by this database connection.
      def aquired_lock?
        query("SELECT CONNECTION_ID() = IS_USED_LOCK(#{quote(name)})") == 1
      end

      # Returns true if this mutex is not locked by this database connection.
      def not_aquired_lock?
        not aquired_lock?
      end

      # Returns a string representation of this DatabaseMutex instance.
      def to_s
        "#<#{self.class} #{name}>"
      end

      alias inspect to_s

      private

      # The quote method returns a string that is suitable for inclusion in an
      # SQL query as the value of a parameter.
      def quote(value)
        ActiveRecord::Base.connection.quote(value)
      end

      # The counter method generates a unique name for the mutex's internal
      # counter variable. This name is used as part of the SQL query to set
      # and retrieve the counter value.
      def counter
        encoded_name = ?$ +
          Digest::MD5.base64digest(name).delete('^A-Za-z0-9+/').
          gsub(/[+\/]/, ?+ => ?_, ?/ => ?.)
        if encoded_name.size <= 64
          "@#{encoded_name}"
        else
          # This should never happen:
          raise MutexInvalidState, "counter name too long: >64 characters"
        end
      end

      # The increase_counter method increments the internal counter value for
      # this mutex instance.
      def increase_counter
        query("SET #{counter} = IF(#{counter} IS NULL OR #{counter} = 0, 1, #{counter} + 1)")
      end

      # The decrease_counter method decrements the internal counter value for #
      # this mutex instance.
      def decrease_counter
        query("SET #{counter} = #{counter} - 1")
      end

      # The counter_value method returns the current value of the internal
      # counter variable for this mutex instance as an integer number.
      def counter_value
        query("SELECT #{counter}").to_i
      end

      # The counter_zero? method returns true if the internal counter value for
      # this mutex instance is zero, otherwise false.
      def counter_zero?
        counter_value.zero?
      end

      # The lock_with_timeout method attempts to acquire the mutex lock for
      # the given name and returns true if successful. If the mutex is already
      # locked by another database connection, it raises a MutexLocked
      # exception after the specified timeout period. A MutexSystemError is
      # raised if system error occurs while acquiring lock.
      def lock_with_timeout(opts = {})
        if aquired_lock?
          increase_counter
          true
        else
          timeout = opts[:timeout] || 1
          case query("SELECT GET_LOCK(#{quote(name)}, #{timeout})")
          when 1
            increase_counter
            true
          when 0
            raise MutexLocked, "mutex '#{name}' is already locked"
          when nil
            raise MutexSystemError, "mutex '#{name}' not locked due to system error"
          end
        end
      end

      # The query method executes an SQL statement +sql+ and returns the
      # result.
      def query(sql)
        if result = self.class.db.execute(sql)
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
