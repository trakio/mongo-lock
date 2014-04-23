module Mongo
  class Lock
    module Drivers
      class Mongo < Base

        attr_accessor :lock

        def self.release_collection collection, owner=nil
          selector = if owner then { owner: owner } else {} end
          collection.remove(selector)
        end

        def self.ensure_indexes collection
          collection.create_index([
            ['key', ::Mongo::ASCENDING],
            ['owner', ::Mongo::ASCENDING],
            ['expires_at', ::Mongo::ASCENDING]
          ])
          collection.create_index([['ttl', ::Mongo::ASCENDING]],{ expireAfterSeconds: 0 })
        end

        def self.clear_expired collection
          collection.remove expires_at: { '$lt' => Time.now }
        end

        def find_and_modify options
          operation = options[:insert] ? '$setOnInsert' : '$set'
          existing_lock = lock.configuration.collection.find_and_modify({
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
          lock.configuration.collection.remove key: key, owner: options[:owner]
        end

      end
    end
  end
end
