require 'active_record'
require 'active_record/database_mutex/version'
require 'active_record/database_mutex/implementation'

module ActiveRecord
  # This module is mixed into ActiveRecord::Base to provide the mutex methods
  # that return a mutex for a particular ActiveRecord::Base subclass/instance.
  module DatabaseMutex
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
        @mutex ||= Implementation.new(:name => name)
      end
    end

    # Returns a mutex instance for this ActiveRecord instance.
    def mutex
      @mutex ||= Implementation.new(:name => self.class.name)
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::DatabaseMutex
end
