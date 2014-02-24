module Mongo
  class Lock
    class Queries

      attr_accessor :lock

      def self.release_collection collection, owner=nil
        selector = if owner then { owner: owner } else {} end
        collection.remove(selector)
      end

      def self.ensure_indexes collection
        collection.create_index([
          ['key', Mongo::ASCENDING],
          ['owner', Mongo::ASCENDING],
          ['expires_at', Mongo::ASCENDING]
        ])
        collection.create_index([['ttl', Mongo::ASCENDING]],{ expireAfterSeconds: 0 })
      end

      def self.clear_expired collection
        collection.remove expires_at: { '$lt' => Time.now }
      end

      def initialize lock
        self.lock = lock
      end

      def key
        lock.key
      end

      def query
        {
          key: key,
          expires_at: { '$gt' => Time.now }
        }
      end

      def find_or_insert options
        options[:expire_at] = Time.now + options[:expire_in]
        options[:insert] = true
        find_and_modify options
      end

      def find_and_update time, options
        options[:expire_at] = lock.expires_at + time
        find_and_modify options
      end

      def find_and_modify options
        operation = options[:insert] ? '$setOnInsert' : '$set'
        existing_lock = collection.find_and_modify({
          query: query,
          update: {
            operation => {
              key: key,
              owner: options[:owner],
              expires_at: options[:expire_at],
              ttl: options[:expire_at]
            }
          },
          upsert: !!options[:insert]
        })

        if existing_lock
          lock.expires_at = existing_lock['expires_at']
        else
          lock.expires_at = options[:expire_at]
        end

        existing_lock
      end

      def remove options
        collection.remove key: key, owner: options[:owner]
      end

      def is_acquired?
        find_already_acquired.count > 0
      end

      def find_already_acquired
        collection.find({
          key: key,
          owner: lock.configuration.owner,
          expires_at: { '$gt' => Time.now }
        })
      end

      def find_existing
        collection.find(query).first
      end

    end
  end
end
