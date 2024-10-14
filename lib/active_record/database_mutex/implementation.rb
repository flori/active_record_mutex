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
        internal_name # create/check internal_name
      end

      # Returns the name of this mutex as given via the constructor argument.
      attr_reader :name

      # Return of internal name for this mutex of length < 64 characters.
      def internal_name
        @internal_name and return @internal_name
        encoded_name = ?$ + Digest::MD5.base64digest([ self.class.name, name ] * ?#).
          delete('^A-Za-z0-9+/').gsub(/[+\/]/, ?+ => ?_, ?/ => ?.)
        if encoded_name.size <= 64
          @internal_name = encoded_name
        else
          # This should never happen:
          raise MutexInvalidState, "internal_name #{encoded_name} too long: >64 characters"
        end
      end

      # The synchronize method attempts to acquire the mutex lock for the given name
      # and executes the block passed to it. If the lock is already held by another
      # thread, this method will return nil instead of raising an exception.
      #
      # The :nonblock and :timeout options are passed to the lock method,
      # and the the :force option to the unlock method.
      def synchronize(opts = {})
        locked = lock(opts.slice(:nonblock, :timeout)) or return
        yield
      rescue ActiveRecord::DatabaseMutex::MutexLocked
        return nil
      ensure
        locked and unlock opts.slice(:force)
      end

      # The lock method attempts to acquire the mutex lock for the given name
      # and returns true if successful. Note that you can lock the mutex
      # n-times, but it has to be unlocked n-times to be released as well.
      # If the :nonblock option was given, it returns false instead of raising
      # MutexLocked exception when unable to acquire lock without blocking.
      # If a :timeout option with the (nonnegative) timeout in seconds was
      # given, a MutexLocked exception is raised, otherwise the method blocks
      # forever.
      def lock(opts = {})
        if opts[:nonblock]
          begin
            lock_with_timeout timeout: 0
          rescue MutexLocked
            false # If non-blocking and unable to acquire lock, return false.
          end
        else
          timeout = opts[:timeout] || -1
          lock_with_timeout timeout:
        end
      end

      # Unlocks the mutex and returns true iff successful (= was unlocked as
      # many times as locked in this db connection). If the :force option was
      # given the lock is released anyway and true is returned.
      #
      # If the lock doesn't belong to this connection raises a MutexLocked
      # exception.
      def unlock(opts = {})
        if acquired_lock?
          if opts[:force]
            reset_counter
          else
            decrease_counter
          end
          if counter_zero?
            case query("SELECT RELEASE_LOCK(#{quote(internal_name)})")
            when 1
              true
            when 0, nil
              raise MutexUnlockFailed, "unlocking of mutex '#{name}' failed"
            end
          else
            false
          end
        else
          raise MutexUnlockFailed, "unlocking of mutex '#{name}' failed"
        end
      end

      # Unlock this mutex and return self if successful, otherwise (the mutex
      # was not locked, is still locked or doesn't belong the the connection)
      # nil is returned.
      def unlock?(*a)
        self if unlock(*a)
      rescue MutexUnlockFailed
        nil
      end

      # Returns true if this mutex is unlocked at the moment.
      def unlocked?
        query("SELECT IS_FREE_LOCK(#{quote(internal_name)})") == 1
      end

      # Returns true if this mutex is locked at the moment.
      def locked?
        not unlocked?
      end

      # Returns true if this mutex is locked by this database connection.
      def acquired_lock?
        query("SELECT CONNECTION_ID() = IS_USED_LOCK(#{quote(internal_name)})") == 1
      end

      # Returns true if this mutex is not locked by this database connection.
      def not_acquired_lock?
        not acquired_lock?
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
        "@#{internal_name}"
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

      # The reset_counter method resets the internal counter value for this
      # mutex instance to zero.
      def reset_counter
        query("SET #{counter} = 0")
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

      # The lock_with_timeout method attempts to acquire the mutex lock for the
      # given name and returns true if successful. If the :timeout option was
      # given, it raises a MutexLocked exception if unable to acquire lock
      # within that time period, otherwise the method blocks forever. It raises
      # an ArgumentError if the timeout option wasn't provided, a
      # MutexSystemError if a system error occured.
      def lock_with_timeout(opts = {})
        timeout = opts.fetch(:timeout) { raise ArgumentError, 'require :timeout argument' }
        if acquired_lock?
          increase_counter
          true
        else
          case query("SELECT GET_LOCK(#{quote(internal_name)}, #{timeout})")
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
