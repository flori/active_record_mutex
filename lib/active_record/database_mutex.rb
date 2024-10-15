require 'active_record'
require 'active_record/database_mutex/version'
require 'active_record/database_mutex/implementation'

module ActiveRecord
  # This module is mixed into ActiveRecord::Base to provide the mutex methods
  # that return a mutex for a particular ActiveRecord::Base subclass/instance.
  module DatabaseMutex
    # This is the base exception of all mutex exceptions.
    class MutexError < ActiveRecordError; end

    # This exception is raised when an attempt to unlock a mutex fails,
    # typically due to the lock not being held by the current database
    # connection or other system errors.
    class MutexUnlockFailed < MutexError; end

    # This exception is raised when attempting to acquire a lock that is
    # already held by another database connection.
    class MutexLocked < MutexError; end

    # This exception raised when an unexpected situation occurs while managing
    # the mutex lock, such as incorrect encoding or handling of internal mutex
    # names.
    class MutexInvalidState < MutexError; end

    # This exception is raised when an unexpected system-related issue prevents
    # the mutex (lock) from being acquired or managed properly, often due to
    # disk I/O errors, database connection issues, resource limitations, or
    # lock file permissions problems.
    class MutexSystemError < MutexError; end

    def self.included(modul)
      modul.instance_eval do
        extend ClassMethods
      end
    end

    # The for method returns an instance of
    # ActiveRecord::DatabaseMutex::Implementation that is initialized with the
    # given name.
    #
    # @param name [ String ] the mutex name
    #
    # @return [ ActiveRecord::DatabaseMutex::Implementation ]
    def self.for(name)
      Implementation.new(name: name)
    end

    module ClassMethods
      def mutex_name
        @mutex_name ||= [ name, defined?(Rails) ? Rails.env : ENV['RAILS_ENV'] ].compact * ?@
      end

      # The mutex method returns an instance of
      # ActiveRecord::DatabaseMutex::Implementation that is initialized with
      # the name given by the class and environment variables.
      #
      # @return [ActiveRecord::DatabaseMutex::Implementation] the mutex instance
      def mutex
        @mutex ||= Implementation.new(name: mutex_name)
      end
    end

    # The mutex method returns an instance of
    # ActiveRecord::DatabaseMutex::Implementation that is initialized with the
    # name given by the id, the class and environment variables.
    #
    # @return [ActiveRecord::DatabaseMutex::Implementation] the mutex instance
    def mutex
      if persisted?
        @mutex ||= Implementation.new(name: "#{id}@#{self.class.mutex_name}")
      else
        raise MutexInvalidState, "instance #{inspect} not persisted"
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::DatabaseMutex
end
