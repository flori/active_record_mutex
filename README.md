# ActiveRecord::Mutex

## Description

This gem provides a Mutex that is based on ActiveRecord's database connection.
(At the moment this only works for Mysql.) It can be used to synchronise
ruby processes (also on different hosts) via the connected database.

## Installation

You can use rubygems to fetch the gem and install it for you:

```
# gem install active_record_mutex
```

## Usage

To synchronize on a specific ActiveRecord instance you can do this:

```ruby
class Foo < ActiveRecord::Base
end

foo = Foo.find(666)
foo.mutex.synchronize do
  # Critical section of code here
end
```

If you want more control over the mutex and/or give it a special name you can
create Mutex instance like this:

```ruby
my_mutex = ActiveRecord::DatabaseMutex.for('my_mutex')
```

Now you can send all messages directly to the Mutex instance or use the custom
mutex instance to `synchronize` method calls or other operations:

```ruby
my_mutex.synchronize do
  # Critical section of code here
end
```

## Download

The homepage of this library is located at

* https://github.com/flori/active_record_mutex

## Author

[Florian Frank](mailto:flori@ping.de)

## License

This software is licensed under the GPL (Version 2) license, see the file
COPYING.
