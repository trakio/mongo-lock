require 'mongo-lock/configuration'

module Mongo
  class Lock

    class NotAcquiredError < StandardError ; end
    class NotReleasedError < StandardError ; end
    class NotExtendedError < StandardError ; end

    attr_accessor :configuration
    attr_accessor :key
    attr_accessor :acquired
    attr_accessor :expires_at
    attr_accessor :released

    def self.configure options = {}, &block
      defaults = {
        timeout_in: 10,
        limit: 10,
        frequency: 1,
        expires_after: 10,
        raise: false,
        owner: "#{`hostname`.strip}:#{Process.pid}:#{Thread.object_id}"
      }
      defaults = defaults.merge(@@default_configuration) if defined?(@@default_configuration) && @@default_configuration
      @@default_configuration = Configuration.new(defaults, options, &block)
    end

    def self.configuration
      if defined? @@default_configuration
        @@default_configuration
      else
        @@default_configuration = configure
      end
    end

    def self.release_all options = {}
      if options.include? :collection
        release_collection configuration.collection(options[:collection]), options[:owner]
      else
        configuration.collections.each_pair do |key,collection|
          release_collection collection, options[:owner]
        end
      end
    end

    def self.release_collection collection, owner=nil
      selector = if owner then { owner: owner } else {} end
      collection.remove(selector)
    end

    def self.init_and_send key, options = {}, method
      lock = self.new(key, options)
      lock.send(method)
      lock
    end

    def self.acquire key, options = {}
      init_and_send key, options, :acquire
    end

    def self.release key, options = {}
      init_and_send key, options, :release
    end

    def self.acquire! key, options = {}
      init_and_send key, options, :acquire!
    end

    def self.release! key, options = {}
      init_and_send key, options, :release!
    end

    def self.available? key, options = {}
      init_and_send key, options, :available?
    end

    def self.ensure_indexes
      configuration.collections.each_pair do |key, collection|
        collection.create_index([
          ['key', Mongo::ASCENDING],
          ['owner', Mongo::ASCENDING],
          ['expires_at', Mongo::ASCENDING]
        ])
        collection.create_index([['ttl', Mongo::ASCENDING]],{ expireAfterSeconds: 0 })
      end
    end

    def self.clear_expired
      configuration.collections.each_pair do |key,collection|
        collection.remove expires_at: { '$lt' => Time.now }
      end
    end

    def initialize key, options = {}
      self.configuration = Configuration.new self.class.configuration.to_hash, options
      self.key = key
      acquire_if_acquired
    end

    def configure options = {}, &block
      self.configuration = Configuration.new self.configuration.to_hash, options
      yield self.configuration if block_given?
    end

    def acquire options = {}
      options = configuration.to_hash.merge options
      i = 1
      time_spent = 0

      loop do
        # If timeout has expired
        if options[:timeout_in] && options[:timeout_in] < time_spent
          return raise_or_false options

        # If limit has expired
        elsif options[:limit] && options[:limit] < i
          return raise_or_false options

        # If there is an existing lock
        elsif existing_lock = find_or_insert(options)

          # If the lock is owned by me
          if existing_lock['owner'] == options[:owner]
            self.acquired = true
            extend_by options[:expires_after]
            return true
          end

        # If the lock was acquired
        else
          self.acquired = true
          return true

        end

        if options[:frequency].is_a? Proc
          frequency = options[:frequency].call(i)
        else
          frequency = options[:frequency]
        end
        sleep frequency
        time_spent += frequency
        i += 1
      end
    end

    def acquire! options = {}
      options[:raise] = true
      acquire options
    end

    def release options = {}
      options = configuration.to_hash.merge options

      # If the lock has already been released
      if released?
        return true

      # If the lock has expired its as good as released
      elsif expired?
        self.released = true
        self.acquired = false
        return true

      # We must have acquired the lock to release it
      elsif !acquired?
        if acquire options.merge(raise: false)
          return release options
        else
          return raise_or_false options, NotReleasedError
        end

      else
        self.released = true
        self.acquired = false
        collection.remove key: key, owner: options[:owner]
        return true
      end
    end

    def release! options = {}
      options[:raise] = true
      release options
    end

    def raise_or_false options, error = NotAcquiredError
      raise error if options[:raise]
      false
    end

    def find_or_insert options
      to_expire_at = Time.now + options[:expires_after]
      existing_lock = collection.find_and_modify({
        query: query,
        update: {
          '$setOnInsert' => {
            key: key,
            owner: options[:owner],
            expires_at: to_expire_at,
            ttl: to_expire_at
          }
        },
        upsert: true
      })

      if existing_lock
        self.expires_at = existing_lock['expires_at']
      else
        self.expires_at = to_expire_at
      end

      existing_lock
    end

    def extend_by time, options = {}
      options = configuration.to_hash.merge options

      # Can't extend a lock that hasn't been acquired
      if !acquired?
        return raise_or_false options, NotExtendedError

      # Can't extend a lock that has started
      elsif expired?
        return raise_or_false options, NotExtendedError

      else
        to_expire_at = expires_at + time
        existing_lock = collection.find_and_modify({
          query: query,
          update: {
            '$set' => {
              key: key,
              owner: options[:owner],
              expires_at: to_expire_at,
              ttl: to_expire_at
            }
          },
          upsert: true
        })
        true
      end
    end

    def extend options = {}
      time = configuration.to_hash.merge(options)[:expires_after]
      extend_by time, options
    end

    def extend_by! time, options = {}
      options[:raise] = true
      extend_by time, options
    end

    def extend! options = {}
      options[:raise] = true
      extend options
    end

    def available? options = {}
      options = configuration.to_hash.merge options
      existing_lock = collection.find(query).first
      !existing_lock || existing_lock['owner'] == options[:owner]
    end

    def query
      {
        key: key,
        expires_at: { '$gt' => Time.now }
      }
    end

    def acquired?
      !!acquired && !expired?
    end

    def expired?
      !!(expires_at && expires_at < Time.now)
    end

    def released?
      !!released
    end

    def acquire_if_acquired
      if (collection.find({
          key: key,
          owner: configuration.owner,
          expires_at: { '$gt' => Time.now }
        }).count > 0)
        self.acquired = true
      end
    end

  end
end
