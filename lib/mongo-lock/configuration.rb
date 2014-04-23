module Mongo
  class Lock
    class Configuration

      attr_accessor :connections
      attr_accessor :limit
      attr_accessor :timeout_in
      attr_accessor :frequency
      attr_accessor :expire_in
      attr_accessor :owner
      attr_accessor :should_raise
      attr_accessor :driver

      def initialize defaults, options, &block
        options = defaults.merge(options)
        options[:collections] ||= {}
        if options[:collection]
          options[:collections][:default] = options[:collection]
        end
        options.each_pair do |key,value|
          self.send(:"#{key}=",value)
        end
        yield self if block_given?
      end

      def collection= collection
        collections[:default] = choose_driver collection
      end

      def collection collection = :default
        collection = collection.to_sym if collection.is_a? String
        if collection.is_a? Symbol
          collections[collection]
        else
          collection
        end
      end

      def collections= collections
        @collections = choose_driver collections
      end

      def set_collections_keep_default collections
        collections[:default] = @collections[:default]
        @collections = collections
      end

      def collections
        @collections ||= {}
      end

      def choose_driver provided_collections
        collections = provided_collections.clone
        collections = collections.values if collections.is_a? Hash

        if collections.is_a? Array
          collection = collections.first
          collection_class = collections.map{ |x| x.class }.uniq
          raise MixedCollectionsError.new "Collections must be of the same class" if collection_class.size > 1
        else
          collection = collections
        end

        if collection.is_a? Moped::Collection
          require 'mongo-lock/drivers/moped'
          self.driver = Mongo::Lock::Drivers::Moped
        elsif collection.is_a?(Mongo::Collection) or collection.nil? or collection.is_a?(String) or collection.is_a?(Symbol)
          require 'mongo-lock/drivers/mongo'
          self.driver = Mongo::Lock::Drivers::Mongo
        else
          raise InvalidCollectionError.new "#{collection.class.name} is not a valid collection class"
        end

        provided_collections
      end

      def driver= driver
        if driver.is_a? String
          driver = "::Mongo::Lock::Drivers::#{driver.camelize}".constantize
        end
        @driver = driver
      end

      def to_hash
        {
          collections: collections,
          timeout_in: timeout_in,
          limit: limit,
          frequency: frequency,
          expire_in: expire_in,
          owner: owner,
          driver: driver,
          should_raise: should_raise
        }
      end

      def owner
        if @owner.is_a? Proc
          @owner.call.to_s
        else
          @owner.to_s
        end
      end

      def process_collection_options options
        options = array_of_collections options
        options = add_single_collection_to_collections options
        options = use_registered_collections_if_empty options
        options
      end

      def array_of_collections options
        options[:collections] = options[:collections].try(:values) || options[:collections] || []
        options
      end

      def add_single_collection_to_collections options
        if options[:collection].is_a? Symbol
          options[:collections] << self.collection(options[:collection])
        elsif options[:collection]
          options[:collections] << options[:collection]
        end
        options
      end

      def use_registered_collections_if_empty options
        if options[:collections].empty?
          options[:collections] = self.collections.values
        end
        options
      end

    end
  end
end