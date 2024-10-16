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

      # The initialize method initializes an instance of the DatabaseMutex
      # class by setting its name and internal_name attributes.
      #
      # @param opts [ Hash ] options hash containing the **name** key
      #
      # @option opts name [ String ] name for the mutex, required.
      #
      # @raise [ ArgumentError ] if no **name** option is provided in the options hash.
      def initialize(opts = {})
        @name = opts[:name].to_s
        @name.size != 0 or raise ArgumentError, "mutex requires a nonempty :name argument"
        internal_name # create/check internal_name
      end

      # Returns the name of this mutex as given via the constructor argument.
      attr_reader :name

      # The internal_name method generates an encoded name for this mutex
      # instance based on its class and {name} attributes and memoizes it.
      #
      # @return [ String ] the encoded name of length <= 64 characters
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

      # The lock_name method generates the name for the mutex's internal lock
      # variable based on its class and {name} attributes, prefixing it with a
      # truncated version of the name that only includes printable characters.
      #
      # @return [ String ] the generated lock name
      def lock_name
        prefix_name = name.gsub(/[^[:print:]]/, '')[0, 32]
        prefix_name + ?= + internal_name
      end

      # The synchronize method attempts to acquire a mutex lock for the given name
      # and executes the block passed to it. If the lock is already held by another
      # database connection, this method will return nil instead of raising an
      # exception and not execute the block. #
      #
      # This method provides a convenient way to ensure that critical sections of code
      # are executed while holding the mutex lock. It attempts to acquire the lock using
      # the underlying locking mechanisms (such as {lock} and {unlock}) and executes
      # the block passed to it.
      #
      # The **block** and **timeout** options are passed to the {lock} method
      # and configure the way the lock is acquired.
      #
      # The **force** option is passed to the {unlock} method, which will force the
      # lock to open if true.
      #
      # @example
      #   foo.mutex.synchronize { do_something_with foo } # wait forever and never give up
      #
      # @example
      #   foo.mutex.synchronize(timeout: 5) { do_something_with foo } # wait 5s and give up
      #
      # @example
      #   unless foo.mutex.synchronize(block: false) { do_something_with foo }
      #     # try again later
      #   end
      #
      # @param opts [ Hash ] Options hash containing the **block**, **timeout**, or **force** keys
      #
      # @yield [ Result ] The block to be executed while holding the mutex lock
      #
      # @return [ Nil or result of yielded block ] depending on whether the lock was acquired
      def synchronize(opts = {})
        locked = lock(opts.slice(:block, :timeout)) or return
        yield
      rescue ActiveRecord::DatabaseMutex::MutexLocked
        return nil
      ensure
        locked and unlock opts.slice(:force)
      end

      # The lock method attempts to acquire the mutex lock for the configured
      # name and returns true if successful, that means #{locked?} and
      # #{owned?} will be true. Note that you can lock the mutex n-times, but
      # it has to be unlocked n-times to be released as well.
      #
      # If the **block** option was given as false, it returns false instead of
      # raising MutexLocked exception when unable to acquire lock without blocking.
      #
      # If a **timeout** option with the (nonnegative) timeout in seconds was
      # given, a MutexLocked exception is raised after this time, otherwise the
      # method blocks forever.
      #
      # If the **raise** option is given as false, no MutexLocked exception is raised,
      # but false is returned.
      #
      # @param opts [ Hash ] the options hash
      #
      # @option opts [ true, false ] block, defaults to true
      # @option opts [ true, false ] raise, defaults to true
      # @option opts [ Integer, nil ] timeout, defaults to nil, which means wait forever
      #
      # @return [ true, false ] depending on whether lock was acquired
      def lock(opts = {})
        opts = { block: true, raise: true }.merge(opts)
        if opts[:block]
          timeout = opts[:timeout] || -1
          lock_with_timeout timeout:
        else
          begin
            lock_with_timeout timeout: 0
          rescue MutexLocked
            false # If non-blocking and unable to acquire lock, return false.
          end
        end
      rescue MutexLocked
        if opts[:raise]
          raise
        else
          return false
        end
      end

      # The unlock method releases the mutex lock for the given name and
      # returns true if successful. If the lock doesn't belong to this
      # connection raises a MutexUnlockFailed exception.
      #
      # @param opts [ Hash ] the options hash
      #
      # @option opts [ true, false ] raise if false won't raise MutexUnlockFailed, defaults to true
      # @option opts [ true, false ] force if true will force the lock to open, defaults to false
      #
      # @raise [ MutexUnlockFailed ] if unlocking failed and raise was true
      #
      # @return [ true, false ] true if unlocking was successful, false otherwise
      def unlock(opts = {})
        opts = { raise: true, force: false }.merge(opts)
        if owned?
          if opts[:force]
            reset_counter
          else
            decrement_counter
          end
          if counter_zero?
            case query("SELECT RELEASE_LOCK(#{quote(lock_name)})")
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
      rescue MutexUnlockFailed
        if opts[:raise]
          raise
        else
          return false
        end
      end

      # The unlock? method returns self if the mutex could successfully
      # unlocked, otherwise it returns nil.
      #
      # @return [self, nil] self if the mutex was unlocked, nil otherwise
      def unlock?(opts = {})
        opts = { raise: false }.merge(opts)
        self if unlock(opts)
      end

      # The unlocked? method checks whether the mutex is currently free and not
      # locked by any database connection.
      #
      # @return [ true, false ] true if the mutex is unlocked, false otherwise
      def unlocked?
        query("SELECT IS_FREE_LOCK(#{quote(lock_name)})") == 1
      end

      # The locked? method returns true if this mutex is currently locked by
      # any database connection, the opposite of {unlocked?}.
      #
      # @return [ true, false ] true if the mutex is locked, false otherwise
      def locked?
        not unlocked?
      end

      # Returns true if the mutex is was acquired on this database connection.
      def owned?
        query("SELECT CONNECTION_ID() = IS_USED_LOCK(#{quote(lock_name)})") == 1
      end

      # Returns true if this mutex was not acquired on this database connection,
      # the opposite of {owned?}.
      def not_owned?
        not owned?
      end

      # The to_s method returns a string representation of this DatabaseMutex
      # instance.
      #
      # @return [ String ] the string representation of this DatabaseMutex instance
      def to_s
        "#<#{self.class} #{name}>"
      end

      alias inspect to_s

      private

      # The quote method returns a string that is suitable for inclusion in an
      # SQL query as the value of a parameter.
      #
      # @param value [ Object ] the object to be quoted
      #
      # @return [ String ] the quoted string
      def quote(value)
        ActiveRecord::Base.connection.quote(value)
      end

      alias counter_name internal_name

      # The counter method generates a unique name for the mutex's internal
      # counter variable. This name is used as part of the SQL query to set and
      # retrieve the counter value.
      #
      # @return [String] the unique name for the mutex's internal counter variable.
      def counter
        "@#{counter_name}"
      end

      # The increment_counter method increments the internal counter value for
      # this mutex instance.
      def increment_counter
        query("SET #{counter} = IF(#{counter} IS NULL OR #{counter} = 0, 1, #{counter} + 1)")
      end

      # The decrement_counter method decrements the internal counter value for #
      # this mutex instance.
      def decrement_counter
        query("SET #{counter} = #{counter} - 1")
      end

      # The reset_counter method resets the internal counter value for this
      # mutex instance to zero.
      def reset_counter
        query("SET #{counter} = 0")
      end

      # The counter_value method returns the current value of the internal
      # counter variable for this mutex instance as an integer number.
      #
      # @return [ Integer ] the current value of the internal counter variable
      def counter_value
        query("SELECT #{counter}").to_i
      end

      # The counter_zero? method checks whether the internal counter value for
      # this mutex instance is zero.
      #
      # @return [ true, false ] true if the counter value is zero, false otherwise
      def counter_zero?
        counter_value.zero?
      end

      # The lock_with_timeout method attempts to acquire the mutex lock for the
      # given name and returns true if successful.
      #
      # If the :timeout option was given as a nonnegative value of seconds, it
      # raises a MutexLocked exception if unable to acquire lock within that
      # time period, otherwise the method blocks forever.
      #
      # @param opts [ Hash ] options hash containing the :timeout key
      #
      # @option opts [ Integer ] timeout, defaults to nil, but is required
      #
      # @raise [ ArgumentError ] if no :timeout option is provided in the options hash
      # @raise [ MutexLocked ] if the mutex is already locked in another database connection
      # @raise [ MutexSystemError ] if a system error occured
      #
      # @return [ true, false ] depending on whether lock was acquired
      def lock_with_timeout(opts = {})
        timeout = opts.fetch(:timeout) { raise ArgumentError, 'require :timeout argument' }
        if owned?
          increment_counter
          true
        else
          case query("SELECT GET_LOCK(#{quote(lock_name)}, #{timeout})")
          when 1
            increment_counter
            true
          when 0
            raise MutexLocked, "mutex '#{name}' is already locked"
          when nil
            raise MutexSystemError, "mutex '#{name}' not locked due to system error"
          end
        end
      end

      # The query method executes an SQL statement and returns the result.
      #
      # @param sql [ String ] the SQL statement to be executed
      #
      # @return [ Integer, nil ] the result of the SQL execution or nil if it
      # failed
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
