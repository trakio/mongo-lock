module Mongo
  class Lock
    class Configuration

      attr_accessor :connections
      attr_accessor :limit
      attr_accessor :timeout_in
      attr_accessor :frequency
      attr_accessor :expires_after
      attr_accessor :owner
      attr_accessor :raise

      def initialize defaults, options, &block
        options = defaults.merge(options)
        options[:collections] ||= {}
        if options[:collection]
          options[:collections][:default] = options[:collection]
        end
        options.each_pair do |key,value|
          self.send(:"#{key}=",value)
        end
      end

      def collection= collection
        collections[:default] = collection
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
        @collections = collections
      end

      def set_collections_keep_default collections
        collections[:default] = @collections[:default]
        @collections = collections
      end

      def collections
        @collections ||= {}
      end

      def to_hash
        {
          timeout_in: timeout_in,
          limit: limit,
          frequency: frequency,
          expires_after: expires_after,
          owner: owner,
          raise: raise
        }
      end

    end
  end
end