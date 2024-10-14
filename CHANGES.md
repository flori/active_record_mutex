# Changes

## 2024-10-14 v3.0.0

### New Features

*   **Improved Mutex Name Generation**: Introduced the `internal_name` method
to generate internal mutex names, replacing the previous encoded name approach.

*   **Enhanced Counter Logic**: Updated the `counter` method to use
`internal_name`, ensuring accurate counter values.

*   **Support for all_images**: Added support for the `all_images` gem,
enabling seamless integration with multiple Ruby versions.

*   **Docker Compose Support**: Included a `docker-compose.yml` file for
streamlined testing and development, allowing users to easily set up a test
environment.

*   **direnv Integration**: Integrated direnv for simplified configuration
management, ensuring a consistent and reliable testing experience.

### Documentation and Testing

*   **Thread-Safe Testing**: Added tests for multiple thread synchronization
using the `synchronize` method with nonblock option.

*   **Improved Test Cases**: Updated test cases for lock acquisition, release,
and timeout handling.

*   **Additional Documentation**: Added more documentation comments to enhance
understanding.

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
