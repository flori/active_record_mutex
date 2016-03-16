module ActiveRecord
  module DatabaseMutex
    class Implementation
      # Creates a mutex with the name given with the option :name.
      def initialize(opts = {})
        @name = opts[:name] or raise ArgumentError, "mutex requires a :name argument"
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
        locked && unlock
      end

      # Locks the mutex and returns true if successful. If the mutex is
      # already locked and the timeout in seconds is given as the :timeout
      # option, this method raises a MutexLocked exception after that many
      # seconds. If the :timeout option wasn't given, this method blocks until
      # the lock could be aquired.
      def lock(opts = {})
        if opts[:nonblock] # XXX document
          begin
            lock_with_timeout :timeout => 0
          rescue MutexLocked
          end
        elsif opts[:timeout]
          lock_with_timeout opts
        else
          spin_timeout = opts[:spin_timeout] || 1 # XXX document
          begin
            lock_with_timeout :timeout => spin_timeout
          rescue MutexLocked
            retry
          end
        end
      end

      # Unlocks the mutex and returns true if successful. Otherwise this method
      # raises a MutexLocked exception.
      def unlock(*)
        case query("SELECT RELEASE_LOCK(#{quote_value(name)})")
        when 1      then true
        when 0, nil then raise MutexUnlockFailed, "unlocking of mutex '#{name}' failed"
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
        query("SELECT IS_FREE_LOCK(#{quote_value(name)})") == 1
      end

      # Returns true if this mutex is locked at the moment.
      def locked?
        not unlocked?
      end

      # Returns true if this mutex is locked by this database connection.
      def aquired_lock?
        query("SELECT CONNECTION_ID() = IS_USED_LOCK(#{quote_value(name)})") == 1
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

      def quote_value(value)
        ActiveRecord::Base.connection.quote(value)
      end

      def lock_with_timeout(opts = {})
        timeout = opts[:timeout] || 1
        case query("SELECT GET_LOCK(#{quote_value(name)}, #{timeout})")
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

