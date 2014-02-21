require 'mongo-lock/configuration'

module Mongo
  class Lock

    attr_accessor :configuration

    def self.configure options = {}, &block
      @@default_configuration = Configuration.new({}, options, &block)
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

    def initialize key, options = {}
      @configuration ||= Configuration.new self.class.configuration.to_hash, options
    end

  end
end
