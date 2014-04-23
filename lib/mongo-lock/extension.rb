module Mongo
  class Lock
    module Extension

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

    end
  end
end
