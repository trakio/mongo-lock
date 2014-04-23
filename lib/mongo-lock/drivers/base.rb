module Mongo
  class Lock
    module Drivers
      class Base

        attr_accessor :lock

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

        def is_acquired?
          find_already_acquired.count > 0
        end

      end
    end
  end
end
