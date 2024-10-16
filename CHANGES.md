# Changes

## 2024-10-16 v3.2.1

* Refactor DatabaseMutex implementation:
  * Change `@name` and `mutex.name` to downcase and freeze values
  * Update tests to reflect new behavior

## 2024-10-16 v3.2.0

* DatabaseMutex improvements:
  * Improved lock name generation in `lock_name` method.
  * Modified SQL queries to use `lock_name` instead of `internal_name`.
  * Added `lock_exists?` and `test_all_mutexes` methods for testing mutex
    creation and querying.

## 2024-10-16 v3.1.0

* Changes for **3.1.0**:
  * Implemented `all_mutexes` method in ActiveRecord::DatabaseMutex
  * Added `MutexInfo` class as a subclass of OpenStruct
  * Updated `active_record_mutex.gemspec` to use **0.6** version of `ostruct`
  * Removed `tins` dependency

## 2024-10-15 v3.0.0

### Major Enhancements

* **Renamed method names**: Updated `acquired_lock?` to `owned?` and
  `not_aquired_lock?` to `not_owned?` to better reflect their functionality.
* **Enhanced documentation**: Improved documentation for several methods,
  providing clearer explanations of their purpose and behavior.
* **Synchronize method updates**: The synchronize method now accepts a `:block`
  option instead of `:nonblock`, allowing for more flexibility in locking and
  unlocking mutexes. Additionally, the `lock` method has been updated to handle
  this new option.

### New Features

* **Timeout handling**: Introduced the `:raise` option to the lock method,
  which defaults to true. If set to false, no MutexLocked exception is raised
  when the timeout expires.
* **Internal name generation**: Added the `internal_name` method for generating
  internal mutex names, replacing encoded names in counter logic.
* **Improved unlock behavior**: Modified the unlock method to raise
  MutexUnlockFailed if the lock doesn't belong to this connection or return
  false if `:raise` is false.

### Refactorings

* **Simplified database setup**: Updated test helper to use a more
  straightforward approach for setting up databases.
* **Ensured counter length**: Added checks to ensure counter names are within
  the allowed range, preventing potential issues with MySQL variable name
  lengths.
* **Refactored support for DATABASE_URL**: Improved support for the
  `DATABASE_URL` environment variable in tests.

### Other Changes

* **Updated documentation**: Reflected current gem installation methods and API
  changes in README.md.
* **Improved testing**: Added test cases for lock acquisition, release, and
  timeout handling, as well as multiple threads scenarios.
* **Removed Travis CI config**: Removed configuration files related to Ruby
  versioning and CodeClimate reporting.

### Documentation Updates

* **Added CHANGES.md file**: Included a changelog file to keep track of changes
  across releases.
* **Refactored database mutex documentation**: Improved documentation for
  methods and exception classes.
* **Updated test cases**: Updated example usage, test updates, and refactorings
  related to the `DATABASE_URL` environment variable.

## 2016-12-07 v2.5.1

* **Specify correct version of activerecord**

## 2016-12-07 v2.5.0

* Be compatible with rails ~>5.0 versions
  + Updated dependencies to support Rails **5.0**
* Start simplecov
  + Added SimpleCov integration using `simplecov`
* use command to push reports
  + Updated CodeClimate reporting to use a custom command
* Use new way to use codeclimate
  + Switched to the latest CodeClimate API usage method

## 2016-11-23 v2.4.0

* Revert changes made in later **2.3** versions
* Only check size for `mysql` version `>= 5.7`

## 2016-09-07 v2.3.8

* **Significant Changes**
  + Test more rubies
  + Use a normal table for counters instead of temporary tables to avoid issues
    on replicating setups with enforced GTID consistency.

…

## 2016-08-24 v2.3.3

* **Only check size for MySQL version >= 5.7**
  + Changed logic to only consider size checks for MySQL versions greater than
    or equal to **5.7**.

## 2016-08-23 v2.3.2

* **Restrictions on variable name length**:
  + Added check to prevent long variable names in MySQL 5.7

## 2016-08-23 v2.3.1

* **Encode counter name to conform to MySQL rules**
  + Changed `counter_name` to use
  `code:mysql_real_escape_string(code:counter_name)` in the code.

## 2016-08-23 v2.3.0

* Use shorter method names
* Implement counter logic to allow nesting of locks (using `code`: `counter_logic`)
* Work with mysql 5.5 and 5.6 semantics

## 2016-08-19 v2.2.1

* **Added support for `Rails.env`**
  + Now uses `Rails.env` instead of hardcoded environment variable names.

## 2016-08-19 v2.2.0

* Make locks rails environments independent
* Disable workaround for wonky mysql behavior
  + Use `simplecov` for code coverage instead of a workaround
* Update to work with Rails environments independently 

## 2014-12-12 v2.0.0

#### Changes

* Change semantic of `ActiveRecord::Base#mutex`

#### Documentation

* Improve and reflect changes
* Add license information
* Add codeclimate token

## 2013-11-18 v1.0.1

* **Avoid annoying rubygems warning**
  + Added a fix to prevent the RubyGems warning from appearing.

## 2012-05-07 v1.0.0

* **Avoid conflicts with top level `Mutex` class**
  + Changes to avoid naming conflict with Ruby's built-in `Mutex` class.

## 2011-07-18 v0.0.1

  * Start
