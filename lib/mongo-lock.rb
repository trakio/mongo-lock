require 'mongo-lock/configuration'
require 'mongo-lock/drivers/base'
require 'mongo-lock/convenience_methods'
require 'mongo-lock/send_with_raise'
require 'mongo-lock/acquisition'
require 'mongo-lock/release'
require 'mongo-lock/extension'

# If we are using Rails then we will include the Mongo::Lock railtie.
if defined?(Rails)
  require "mongo-lock/railtie"
end

module Mongo
  class Lock

    extend Mongo::Lock::ConvenienceMethods
    include Mongo::Lock::SendWithRaise
    include Mongo::Lock::Acquisition
    include Mongo::Lock::Release
    include Mongo::Lock::Extension

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
        owner: Proc.new { "#{`hostname`.strip}:#{Process.pid}:#{Thread.current.object_id}" }
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

    def initialize key, options = {}
      self.configuration = Configuration.new self.class.configuration.to_hash, options
      self.key = retrieve_lock_key key
      acquire_if_acquired
    end

    def configure options = {}, &block
      self.configuration = Configuration.new self.configuration.to_hash, options
      yield self.configuration if block_given?
    end

    def available? options = {}
      options = inherit_options options
      existing_lock = driver.find_existing
      !existing_lock || existing_lock['owner'] == options[:owner]
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
