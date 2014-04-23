module Mongo
  class Lock
    module Drivers
      class Moped < Base

        def self.release_collection collection, owner=nil
          selector = if owner then { owner: owner } else {} end
          collection.find(selector).remove_all
        end

        def self.ensure_indexes collection
          collection.indexes.create({ key: 1, owner: 1, expires_at: 1 })
          collection.indexes.create({ ttl: 1 }, { expireAfterSeconds: 0 })
        end

        def self.clear_expired collection
          collection.find(expires_at: { '$lt' => Time.now }).remove_all
        end

        def find_and_modify options
          operation = options[:insert] ? '$setOnInsert' : '$set'
          existing_lock = lock.configuration.collection.
            find(query).
            modify({
              operation => {
                key: key,
                owner: options[:owner],
                expires_at: options[:expire_at],
                ttl: options[:expire_at]
              }
            }, { upsert: !!options[:insert] })
          existing_lock = nil if existing_lock == {} # Moped returns {} for an empty result

          if existing_lock
            lock.expires_at = existing_lock['expires_at']
          else
            lock.expires_at = options[:expire_at]
          end

          existing_lock
        end

        def remove options
          lock.configuration.collection.find( key: key, owner: options[:owner] ).remove_all
        end

      end
    end
  end
end
