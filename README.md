# ActiveRecord::Mutex

## Description

This gem provides a Mutex that is based on ActiveRecord's database connection.
(At the moment this only works for Mysql.) It can be used to synchronise
ruby processes (also on different hosts) via the connected database.

## Installation

You can use rubygems to fetch the gem and install it for you:

    # gem install active_record_mutex

You can also put this line into your Rails environment.rb file

    config.gem 'active_record_mutex'

and install the gem via

    $ rake gems:install

## Usage

If you want to synchronize method calls to your model's methods you can easily
do this by passing a mutex instance to ActiveRecord's synchronize class method.
This mutex instance will be named Foo like the ActiveRecord was named:

  class Foo < ActiveRecord::Base
    def foo
    end

    synchronize :foo, :with => :mutex
  end

If you want more control over the mutex and/or give it a special name you can
create Mutex instance like this:

    my_mutex = ActiveRecord::Mutex::Mutex.new(:name => 'my_mutex')

Now you can send all messages directly to the Mutex instance.

## Changes

* 2014-12-12 Release 2.0.0
* 2014-12-12 Add license information
* 2014-12-09 Adapt to newer Rails versions' API

## Download

The homepage of this library is located at

* https://github.com/flori/active_record_mutex

## Author

[Florian Frank](mailto:flori@ping.de)

## License

This software is licensed under the GPL (Version 2) license, see the file
COPYING.
