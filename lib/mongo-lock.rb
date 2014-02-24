require 'mongo-lock/configuration'
require 'mongo-lock/mongo_queries'
require 'mongo-lock/class_convenience_methods'

module Mongo
  class Lock

    extend Mongo::Lock::ClassConvenienceMethods

    class NotAcquiredError < StandardError ; end
    class NotReleasedError < StandardError ; end
    class NotExtendedError < StandardError ; end

    attr_accessor :configuration
    attr_accessor :key
    attr_accessor :acquired
    attr_accessor :expires_at
    attr_accessor :released
    attr_accessor :query

    def self.configure options = {}, &block
      defaults = {
        timeout_in: false,
        limit: 100,
        frequency: 1,
        expire_in: 10,
        raise: false,
        owner: Proc.new { "#{`hostname`.strip}:#{Process.pid}:#{Thread.object_id}" }
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
        Mongo::Lock::MongoQueries.release_collection configuration.collection(options[:collection]), options[:owner]
      else
        configuration.collections.each_pair do |key,collection|
          Mongo::Lock::MongoQueries.release_collection collection, options[:owner]
        end
      end
    end

    def self.ensure_indexes
      configuration.collections.each_pair do |key, collection|
        Mongo::Lock::MongoQueries.ensure_indexes collection
      end
    end

    def self.clear_expired
      configuration.collections.each_pair do |key,collection|
        Mongo::Lock::MongoQueries.clear_expired collection
      end
    end


    def initialize key, options = {}
      self.configuration = Configuration.new self.class.configuration.to_hash, options
      self.key = key
      self.query = Mongo::Lock::MongoQueries.new self
      acquire_if_acquired
    end

    # API

    def configure options = {}, &block
      self.configuration = Configuration.new self.configuration.to_hash, options
      yield self.configuration if block_given?
    end

    def acquire options = {}
      options = inherit_options options
      i = 1
      time_spent = 0

      loop do
        result = try_acquire options, i, time_spent
        return result unless result.nil?

        frequency = call_if_proc options[:frequency], i
        sleep frequency
        time_spent += frequency
        i += 1
      end
    end

    def try_acquire options, i, time_spent
      # If timeout has expired
      if options[:timeout_in] && options[:timeout_in] < time_spent
        return raise_or_false options

      # If limit has expired
      elsif options[:limit] && options[:limit] < i
        return raise_or_false options

      # If there is an existing lock
      elsif existing_lock = query.find_or_insert(options)
        # If the lock is owned by me
        if existing_lock['owner'] == options[:owner]
          self.acquired = true
          extend_by options[:expire_in]
          return true
        end

      # If the lock was acquired
      else
        self.acquired = true
        return true
      end
    end

    def release options = {}
      options = inherit_options options

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
        query.remove options
        return true
      end
    end

    def extend_by time, options = {}
      options = inherit_options options

      # Can't extend a lock that hasn't been acquired
      if !acquired?
        return raise_or_false options, NotExtendedError

      # Can't extend a lock that has started
      elsif expired?
        return raise_or_false options, NotExtendedError

      else
        query.find_and_update time, options
        true
      end
    end

    def extend options = {}
      time = configuration.to_hash.merge(options)[:expire_in]
      extend_by time, options
    end

    def available? options = {}
      options = inherit_options options
      existing_lock = query.find_existing
      !existing_lock || existing_lock['owner'] == options[:owner]
    end

    # Raise methods

    def acquire! options = {}
      send_with_raise :acquire, options
    end

    def release! options = {}
      send_with_raise :release, options
    end

    def extend_by! time, options = {}
      send_with_raise :extend_by, time, options
    end

    def extend! options = {}
      send_with_raise :extend, options
    end

    # Current state

    def acquired?
      !!acquired && !expired?
    end

    def expired?
      !!(expires_at && expires_at < Time.now)
    end

    def released?
      !!released
    end

    # Utils

    def acquire_if_acquired
      self.acquired = true if query.is_acquired?
    end

    def send_with_raise method, *args
      args.last[:raise] = true
      self.send(method, *args)
    end

    def raise_or_false options, error = NotAcquiredError
      raise error if options[:raise]
      false
    end

    def inherit_options options
      configuration.to_hash.merge options
    end

    def call_if_proc proc, *args
      if proc.is_a? Proc
        proc.call(*args)
      else
        proc
      end
    end

  end
end
