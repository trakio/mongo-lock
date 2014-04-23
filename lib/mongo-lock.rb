require 'mongo-lock/configuration'
require 'mongo-lock/drivers/base'
require 'mongo-lock/class_convenience_methods'
require 'mongo-lock/send_with_raise_methods'

# If we are using Rails then we will include the Mongo::Lock railtie.
if defined?(Rails)
  require "mongo-lock/railtie"
end

module Mongo
  class Lock

    extend Mongo::Lock::ClassConvenienceMethods
    include Mongo::Lock::SendWithRaiseMethods

    class NotAcquiredError < StandardError ; end
    class NotReleasedError < StandardError ; end
    class NotExtendedError < StandardError ; end
    class InvalidCollectionError < StandardError ; end
    class MixedCollectionsError < StandardError ; end

    attr_accessor :configuration
    attr_accessor :key
    attr_accessor :acquired
    attr_accessor :expires_at
    attr_accessor :released

    def self.configure options = {}, &block
      defaults = {
        timeout_in: false,
        limit: 100,
        frequency: 1,
        expire_in: 10,
        should_raise: false,
        driver: options[:driver] || (require('mongo-lock/drivers/mongo') && ::Mongo::Lock::Drivers::Mongo),
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

    def self.ensure_indexes
      configuration.collections.each_pair do |key, collection|
        configuration.driver.ensure_indexes collection
      end
    end

    def self.clear_expired options = {}
      options = configuration.process_collection_options options

      options[:collections].each do |collection|
        configuration.driver.clear_expired collection
      end
    end

    def self.release_all options = {}
      options = configuration.process_collection_options options

      options[:collections].each do |collection|
        configuration.driver.release_collection collection, options[:owner]
      end
    end

    def initialize key, options = {}
      self.configuration = Configuration.new self.class.configuration.to_hash, options
      self.key = retrieve_lock_key key
      acquire_if_acquired
    end

    # API

    def configure options = {}, &block
      self.configuration = Configuration.new self.configuration.to_hash, options
      yield self.configuration if block_given?
    end

    def acquire options = {}, &block
      options = inherit_options options
      i = 1
      time_spent = 0

      loop do
        result = try_acquire options, i, time_spent, &block
        return result unless result.nil?

        frequency = call_if_proc options[:frequency], i
        sleep frequency
        time_spent += frequency
        i += 1
      end
    end

    def try_acquire options, i, time_spent, &block

      # If timeout has expired
      if options[:timeout_in] && options[:timeout_in] < time_spent
        return raise_or_false options

      # If limit has expired
      elsif options[:limit] && options[:limit] < i
        return raise_or_false options

      # If there is an existing lock
      elsif existing_lock = driver.find_or_insert(options)
        # If the lock is owned by me
        if existing_lock['owner'] == options[:owner]
          self.acquired = true
          extend_by options[:expire_in]
          return true
        end

      # If the lock was acquired
      else
        self.acquired = true
        return call_block options, &block
      end
    end

    def call_block options, &block
      if block_given?
        yield self
        release(options)
      end
      true
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
        if acquire options.merge(should_raise: false)
          return release options
        else
          return raise_or_false options, NotReleasedError
        end

      else
        self.released = true
        self.acquired = false
        driver.remove options
        return true
      end
    end

    def extend_by time, options = {}
      options = inherit_options options

      # Can't extend a lock that hasn't been acquired or expired
      if !acquired? || expired?
        return raise_or_false options, NotExtendedError

      else
        driver.find_and_update time, options
        true
      end
    end

    def extend options = {}
      time = configuration.to_hash.merge(options)[:expire_in]
      extend_by time, options
    end

    def available? options = {}
      options = inherit_options options
      existing_lock = driver.find_existing
      !existing_lock || existing_lock['owner'] == options[:owner]
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

    def driver
      @driver ||= configuration.driver.new self
    end

    def retrieve_lock_key key
      case
      when key.respond_to?(:lock_key)  then key.lock_key
      when key.is_a?(Array)            then key.map { |element| retrieve_lock_key(element) }.to_param
      else                                  key.to_param
      end.to_s
    end

    def acquire_if_acquired
      self.acquired = true if driver.is_acquired?
    end

    def raise_or_false options, error = NotAcquiredError
      raise error if options[:should_raise]
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
