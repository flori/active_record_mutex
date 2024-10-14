# ActiveRecord::Mutex

## Description

This gem provides a Mutex that is based on ActiveRecord's database connection.
(At the moment this only works for Mysql.) It can be used to synchronise
ruby processes (also on different hosts) via the connected database.

## Installation

You can use rubygems to fetch the gem and install it for you:

    # gem install active_record_mutex

You can also put this line into your Gemfile

    gem 'active_record_mutex'

## Usage

### Using synchronize for critical sections

To synchronize on a specific ActiveRecord instance you can do this:

    class Foo < ActiveRecord::Base
    end

    foo = Foo.find(666)
    foo.mutex.synchronize do
      # Critical section of code here
    end

If you want more control over the mutex and/or give it a special name you can
create Mutex instance like this:

    my_mutex = ActiveRecord::DatabaseMutex.for('my_mutex')

Now you can send all messages directly to the Mutex instance or use the custom
mutex instance to `synchronize` method calls or other operations:

    my_mutex.synchronize do
      # Critical section of code here
    end

### Low-Level Demonstration: Multiple Process Example

The following example demonstrates how the Mutex works at a lower level, using
direct MySQL connections. This is not intended as a real-world use case, but
rather to illustrate the underlying behavior.

If two processes are connected to the same database, configured via e.g.
`DATABASE_URL=mysql2://root@127.0.0.1:3336/test` and this is process 1:

    # process1.rb
    …
    mutex = ActiveRecord::DatabaseMutex.for('my_mutex')

    lock_result1 = mutex.lock(timeout: 5)
    puts "Process 1: Lock acquired (first): #{lock_result1}"

    puts "Process 1: Waiting for 10s"
    sleep(10)

    lock_result2 = mutex.lock(timeout: 5)
    puts "Process 1: Lock acquired (second): #{lock_result2}"

    mutex.unlock # first
    mutex.unlock # second

    puts "Process 1: Unlocked the mutex twice"

    puts "Process 1: Waiting for 10s"
    sleep(10)

    puts "Process 1: Exiting"

and this process 2:

    # process2.rb
    …
    mutex = ActiveRecord::DatabaseMutex.for('my_mutex')

    begin
      lock_result3 = mutex.lock(timeout: 5)
      puts "Process 2: Lock acquired (first): #{lock_result3}"
    rescue ActiveRecord::DatabaseMutex::MutexLocked
      puts "Process 2: Mutex locked by another process, waiting..."
    end

    puts "Process 2: Waiting for 10s"
    sleep(10)

    puts "Process 2: Trying to lock again"
    lock_result4 = mutex.lock(timeout: 5)
    puts "Process 2: Lock acquired (second): #{lock_result4}"

    puts "Process 2: Exiting"

Running these processes in parallel will output the following:

    Process 1: Lock acquired (first): true
    Process 1: Waiting for 10s
    Process 2: Mutex locked by another process, waiting...
    Process 2: Waiting for 10s
    Process 1: Lock acquired (second): true
    Process 1: Unlocked the mutex twice
    Process 1: Waiting for 10s
    Process 2: Trying to lock again
    Process 2: Lock acquired (second): true
    Process 2: Exiting
    Process 1: Exiting

The two ruby files can be found in the examples subdirectory as
`examples/process1.rb` and `examples/process2.rb`. The necessary configuration
files, `.envrc` (`direnv allow`) and `docker-compose.yml`
(`docker compose up -d`), are also located in the root of this repository.

## Running the tests

First start mysql in docker via `docker compose up -d` and configure your
environment via `direnv allow` as before and then run

    rake test

or with coverage:

    rake test START_SIMPLECOV=1

To test for different ruby versions in docker, run:

    all_images

## Download

The homepage of this library is located at

* https://github.com/flori/active_record_mutex

## Author

[Florian Frank](mailto:flori@ping.de)

## License

This software is licensed under the GPL (Version 2) license, see the file
COPYING.
