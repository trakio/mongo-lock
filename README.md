Mongo::Lock
==========

Key based pessimistic locking for Ruby and MongoDB. Is this key avaliable? Yes - Lock it for me for a sec will you. No - OK I'll just wait here until its ready.

It handles timeouts and and vanishing lock owners (such as machine failures)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongo-lock'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install mongo-lock
```

Build you indexes on any collection that is going to hold locks:

```ruby
Mongo::Lock.ensure_indexes # Will use the collection provided to #configure
```

For this to work you must have configured your collection or collections in when intializing locks, in #configure or .configure.

## Shout outs

We took quite a bit of inspiration from the [redis versions](https://github.com/mlanett/redis-lock) [of this gem](https://github.com/PatrickTulskie/redis-lock) by [@mlanett](https://github.com/mlanett/redis-lock) and [@PatrickTulskie](https://github.com/PatrickTulskie). If you aren't already using MongoDB or are already using Redis in your stack you probably want to think about using one of them.

We also looked at [mongo-locking gem](https://github.com/servio/mongo-locking) by [@servio](https://github.com/servio). It was a bit complicated for ours needs, but if you need to lock related and embedded documents rather than just keys it could be what you need.

## Background

A lock has an expected lifetime. If the owner of a lock disappears (due to machine failure, network failure, process death), you want the lock to expire and another owner to be able to acquire the lock. At the same time, the owner of a lock should be able to extend its lifetime. Thus, you can acquire a lock with a conservative estimate on lifetime, and extend it as necessary, rather than acquiring the lock with a very long lifetime which will result in long waits in the event of failures.

A lock has an owner. Mongo::Lock defaults to using an owner id of HOSTNAME:PID:TID.

## Configuration

Mongo::Lock makes no effort to help configure the MongoDB connection - that's
what the Mongo Ruby Driver is for.

Configuring Mongo::Lock with the Mongo Ruby Driver would look like this:

```ruby
Mongo::Lock.configure collection: Mongo::Connection.new("localhost").db("somedb").collection("locks")
```

Or using Mongoid:

```ruby
Mongo::Lock.configure collection: Mongoid.database.collection("locks")
```

You can add multiple collections with a hash that can be referenced later using symbols:

```ruby
Mongo::Lock.configure collections: { default: Mongoid.database.collection("locks"), other: Mongoid.database.collection("other_locks") }
Mongo::Lock.acquire('my_lock') # Locks in the default collection
Mongo::Lock.acquire('my_lock', collection: :other) # Locks in the other_locks collection
```

You can also configure using a block:

```ruby
Mongo::Lock.configure do |config|
  config.collections: {
    default: Mongoid.database.collection("locks"),
    other: Mongoid.database.collection("other_locks")
  }
end
```

### Acquisition timeout_in

A lock may need more than one attempt to acquire it. Mongo::Lock offers:

```ruby
Mongo::Lock.configure do |config|
  config.timeout_in = false # timeout_in in seconds on acquisition; this defaults to false ie no time limit.
  config.limit = 100 # The limit on the number of acquisition attempts; this defaults to 100.
  config.frequency = 1 # Frequency in seconds for acquisition attempts ; this defaults to 1.
  # acquisition_attempt_frequency can also be given as a proc which will be passed the attempt number
  config.frequency = Proc.new { |x| x**2 }
end
```

### Lock Expiry

A lock will automatically be relinquished once its expiry has passed. Expired locks are cleaned up by [MongoDB's TTL index](http://docs.mongodb.org/manual/tutorial/expire-data/), which may take up to 60 seconds or more depending on load to actually remove expired locks. Expired locks that have not been cleaned out can still be acquire. **You must have built your indexes to ensure expired locks are cleaned out.**

```ruby
Mongo::Lock.configure do |config|
  config.expires_after = false # timeout_in in seconds for lock expiry; this defaults to 10.
end
```

You can remove expired locks yourself with:

```ruby
Mongo::Lock.clean_expired
```


### Raising Errors

If a lock cannot be acquired, released or extended it will return false, you can set the raise option to true to raise a Mongo::Lock::LockNotAcquiredError or Mongo::Lock::LockNotReleasedError.

```ruby
Mongo::Lock.configure do |config|
  config.raise = true # Whether to raise an error when acquire, release or extend fail.
end
```

Using .acquire!, #acquire!, .release!, #release!, #extend_by! and #extend! will also raise exceptions instead of returning false.

### Owner

By default the owner id will be generated using the following Proc:

```ruby
Proc.new { "#{`hostname`.strip}:#{Process.pid}:#{Thread.object_id}" }
```

You can override this with either a Proc that returns any object that responds to to_s, or with any object that responds to #to_s.

```ruby
Mongo::Lock.configure do |config|
  config.owner = ['my', 'owner', 'id']
end
# Or
Mongo::Lock.configure do |config|
  config.owner = Proc.new { [`hostname`.strip, Process.pid] }
end
```

Note: Hosts, threads or processes using the same owner can acquire each others locks.

## Usage

You can use Mongo::Lock's class methods:

```ruby
Mongo::Lock.acquire('my_key', options) do |lock|
  # Do Something here that needs my_key locked
end

lock = Mongo::Lock.new('my_key', options).acquire
# Do Something here that needs my_key locked
lock.release
# or
Mongo::Lock.release('my_key')
```

Or you can initialise your own instance.

```ruby
Mongo::Lock.new('my_key', options).acquire do |lock|
  # Do Something here that needs my_key locked
end

lock = Mongo::Lock.acquire('my_key', options)
# Do Something here that needs my_key locked
lock.release
# or
Mongo::Lock.release('my_key')
```

### Options

When using Mongo::Lock#acquire, Mongo::Lock#release or Mongo::Lock#new after the key you may overide any of the following options:

```ruby
Mongo::Lock.new 'my_key', {
  collection: Mongo::Connection.new("localhost").db("somedb").collection("locks"), # May also be a symbol if that symbol was provided in the collections hash to Mongo::Lock.configure
  timeout_in: 10, # timeout_in in seconds on acquisition; this defaults to false ie no time limit.
  limit: 10, # The limit on the number of acquisition attempts; this defaults to 100.
  frequency: 2, # Frequency in seconds for acquisition attempts ; this defaults to 1.
  expires_after: 10,# timeout_in in seconds for lock expiry; this defaults to 10.
}
```

### Extending lock

You can extend a lock by calling Mongo::Lock#extend_by with the number of seconds to extend the lock.

```ruby
Mongo::Lock.new 'my_key' do |lock|
  lock.extend_by 10
end
```

You can also call Mongo::Lock#extend and it will extend by the lock's expires_after option.

```ruby
Mongo::Lock.new 'my_key' do |lock|
  lock.extend
end
```

### Check you still hold a lock

```ruby
Mongo::Lock.acquire 'my_key', expires_after: 10 do |lock|
  sleep 9
  lock.expired? # False
  sleep 11
  lock.expired? # True
end
```

### Check a key is already locked without acquiring it

```ruby
Mongo::Lock.available? 'my_key'
# Or
lock = Mongo::Lock.new('my_key')
lock.available?
```

### Failures

If Mongo::Lock#acquire cannot acquire a lock within its configuration limits it will return false.

```ruby
unless Mongo::Lock.acquire 'my_key'
  # Maybe try again tomorrow
end
```

If Mongo::Lock#release cannot release a lock because it wasn't acquired it will return false. If it has already been released, or has expired it will do nothing and return true.

```ruby
unless Mongo::Lock.release 'my_key'
  # Eh somebody else should release it eventually
end
```

If Mongo::Lock#extend cannot be extended because it has already been released, it is owned by someone else or it was never acquired it will return false.

```ruby
unless lock.extend_by 10
  # Eh somebody else should release it eventually
end
```

If the raise error option is set to true or you append ! to the end of the method name and you call any of the acquire, release, extend_by or extend methods they will raise a Mongo::Lock::NotAcquiredError, Mongo::Lock::NotReleasedError or Mongo::Lock::NotExtendedError instead of returning false.

```ruby
begin
  Mongo::Lock.acquire! 'my_key'
rescue Mongo::Lock::LockNotAcquiredError => e
  # Maybe try again tomorrow
end

# Or

begin
  Mongo::Lock.acquire 'my_key', raise: true
rescue Mongo::Lock::LockNotAcquiredError => e
  # Maybe try again tomorrow
end
```

## Contributors

Matthew Spence (msaspence)

The bulk of this gem has been developed for and by [trak.io](http://trak.io)

[![trak.io](http://trak.io/assets/images/logo@2x.png =203x37)](http://trak.io)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
