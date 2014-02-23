require 'mongo-lock/configuration'

module Mongo
  class Lock

    class NotAcquiredError < StandardError ; end

    attr_accessor :configuration
    attr_accessor :key
    attr_accessor :acquired

    def self.configure options = {}, &block
      defaults = {
        timeout_in: 10,
        limit: 10,
        frequency: 1,
        expires_after: 10,
      }
      @@default_configuration = Configuration.new(defaults, options, &block)
    end

    def self.configuration
      @@default_configuration
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

    def self.acquire key, options = {}, method = :acquire
      lock = self.new(key, options)
      lock.send(method)
      lock
    end

    def self.lock *args
      acquire *args
    end

    def self.acquire! key, options
      acquire key, options, :acquire!
    end

    def self.lock! *args
      acquire! *args
    end

    def initialize key, options = {}
      self.configuration = Configuration.new self.class.configuration.to_hash, options
      self.key = key
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

    def lock *args
      acquire *args
    end

    def acquire! options
      options[:raise] = true
      acquire options
    end

    def lock! *args
      acquire! *args
    end

    def raise_or_false options
      raise NotAcquiredError if options[:raise]
      false
    end

    def find_or_insert options
      collection.find_and_modify({
        query: {
          key: key,
          expires_at: { '$gt' => Time.now }
        },
        update: {
          '$setOnInsert' => {
            key: key,
            owner: options[:owner],
            expires_at: Time.now + options[:expires_after]
          }
        },
        upsert: true
      })
    end

    def extend_by time

    end

  end
end
