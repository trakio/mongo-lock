Mongo::Lock
==========

Key based pessimistic locking for Ruby and MongoDB. Is this key avaliable? Yes - Lock it for me for a sec will you. No - OK I'll just wait here until its ready.

It correctly handles timeouts and vanishing lock owners (such as machine failures)

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
Mongo::Lock.ensure_indexes # Will use the collection provided to configure
Mongo::Lock.ensure_indexes collection: collection # Provide a collection manually
Mongo::Lock.ensure_indexes collections: [collection1, collection2] # Provide an array of collections
```

If you are using rake you can run:

```
$ bundle exec rake mongo_lock:ensure_indexes
```

For this to work you must have configured your collection or collections in an intializer.


## Shout outs

We took quite a bit of inspiration from the [redis versions](https://github.com/mlanett/redis-lock) [of this gem](https://github.com/PatrickTulskie/redis-lock) by [@mlanett](https://github.com/mlanett/redis-lock) and [@PatrickTulskie](https://github.com/PatrickTulskie). If you aren't already using MongoDB or are already using Redis in your stack you probably want to think about using one of them.

We also looked at [mongo-locking gem](https://github.com/servio/mongo-locking) by [@servio](https://github.com/servio). It was a bit complicated for ours needs, but if you need to lock related and embedded documents rather than just keys it could be what you need.

## Background

A lock has an expected lifetime.
If the owner of a lock disappears (due to machine failure, network failure, process death),
you want the lock to expire and another owner to be able to acquire the lock.
At the same time, the owner of a lock should be able to extend its lifetime.
Thus, you can acquire a lock with a conservative estimate on lifetime, and extend it as necessary,
rather than acquiring the lock with a very long lifetime which will result in long waits in the event of failures.

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
Mongo::Lock.lock('my_lock') # Locks in the locks collection
Mongo::Lock.lock('my_lock', collection: :other) # Locks in the other_locks collection
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


A lock may need more than one attempt to acquire it. Mongo::Lock offers:

```ruby
Mongo::Lock.configure do |config|
  config.timeout_in = false # Timeout in seconds on acquisition; this defaults to false ie no time limit.
  config.limit = 100 # The limit on the number of acquisition attempts; this defaults to 100.
  config.frequency = 1 # Frequency in seconds for acquisition attempts ; this defaults to 1.
  # acquisition_attempt_frequency can also be given as a proc which will be passed the attempt number
  config.frequency = Proc.new { |x| x**2 }
end
```

### Lock Expiry

A lock will automatically be relinquished once its expiry has passed. Expired locks are cleaned up by [MongoDB's TTL index](http://docs.mongodb.org/manual/tutorial/expire-data/), which may take up to 60 or more depending on load to actually remove expired locks. Expired locks that have not been cleaned out can still be acquire. **You must have built your indexes to ensure expired locks are cleaned out.**

```ruby
Mongo::Lock.configure do |config|
  config.expires_after = false # Timeout in seconds for lock expiry; this defaults to 10.
end
```

## Usage

You can Mongo::Lock's class methods:

    Mongo::Lock.lock('my_key', options) do |lock|
      # Do Something here that needs my_key locked
    end
    lock = Mongo::Lock.lock('my_key', options)
    # Do Something here that needs my_key locked
    lock.unlock
    # or
    Mongo::Lock.unlock('my_key')

Or you can initialise your own instance.

    Mongo::Lock.new('my_key', options).lock do |lock|
      # Do Something here that needs my_key locked
    end
    lock = Mongo::Lock.new('my_key', options)
    lock.
    # Do Something here that needs my_key locked
    lock.unlock
    # or
    Mongo::Lock.new('my_key').unlock

### Options

When using Mongo::Lock#lock, Mongo::Lock#unlock or Mongo::Lock#new after the key you may overide any of the following options:
```ruby
Mongo::Lock.new 'my_key', {
  collection: Mongoid.database.collection("locks"), # May also be a symbol if that symbol was provided in the collections hash to Mongo::Lock.configure
  timeout_in: 10, # Timeout in seconds on acquisition; this defaults to false ie no time limit.
  limit: 10, # The limit on the number of acquisition attempts; this defaults to 100.
  frequency: 2, # Frequency in seconds for acquisition attempts ; this defaults to 1.
  expires_after: 10,# Timeout in seconds for lock expiry; this defaults to 10.
}
```

### Extending lock

You can extend a lock by calling Mongo::Lock#extend_by with the number of seconds to extend the lock. This is from now, not from when the lock would have expired by.

```ruby
Mongo::Lock.new 'my_key' do |lock|
  lock.extend_by 10
end
```

### Check you still hold a lock

```ruby
Mongo::Lock.new 'my_key', expires_after: 10 do |lock|
  sleep 9
  lock.expired? # False
  sleep 11
  lock.expired? # True
end
```

### Check a key is locked without acquiring it

```ruby
Mongo::Lock.locked? 'my_key'
# Or
Mongo::Lock.new('my_key').locked?
```

### Acquisition Failures

If Mongo::Lock cannot acquire a lock within its configuration limits it will raise a Mongo::Lock::LockNotAcquired

```ruby
begin
  Mongo::Lock.lock 'my_key'
rescue Mongo::Lock::LockNotAcquired => e
  # Maybe try again tomorrow
end
```

### Aliases

```ruby
Mongo::Lock.acquire # Mongo::Lock.lock
Mongo::Lock#acquire # Mongo::Lock.lock
Mongo::Lock.release # Mongo::Lock.unlock
Mongo::Lock#release # Mongo::Lock.unlock
Mongo::Lock.acquired? # Mongo::Lock.locked?
Mongo::Lock#acquired? # Mongo::Lock.locked?
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
