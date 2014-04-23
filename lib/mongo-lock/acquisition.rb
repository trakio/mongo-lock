module Mongo
  class Lock
    module Acquisition

      def acquire options = {}, &block
        options = inherit_options options
        i = 1
        time_spent = 0

        loop do
          result = try_acquire options, i, time_spent, &block
          return result unless result.nil?

          frequency = call_if_proc options[:frequency], i
          sleep frequency
          time_spent += frequency
          i += 1
        end
      end

      def try_acquire options, i, time_spent, &block

        # If timeout has expired
        if options[:timeout_in] && options[:timeout_in] < time_spent
          return raise_or_false options

        # If limit has expired
        elsif options[:limit] && options[:limit] < i
          return raise_or_false options

        # If there is an existing lock
        elsif existing_lock = driver.find_or_insert(options)
          # If the lock is owned by me
          if existing_lock['owner'] == options[:owner]
            self.acquired = true
            extend_by options[:expire_in]
            return true
          end

        # If the lock was acquired
        else
          self.acquired = true
          return call_block options, &block
        end
      end

      def acquire_if_acquired
        self.acquired = true if driver.is_acquired?
      end

    end
  end
end
