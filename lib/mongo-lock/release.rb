module Mongo
  class Lock
    module Release

      def self.included base
        def base.release_all options = {}
          options = configuration.process_collection_options options

          options[:collections].each do |collection|
            configuration.driver.release_collection collection, options[:owner]
          end
        end
      end

      def release options = {}
        options = inherit_options options

        # If the lock has already been released
        if released?
          return true

        # If the lock has expired its as good as released
        elsif expired?
          self.released = true
          self.acquired = false
          return true

        # We must have acquired the lock to release it
        elsif !acquired?
          if acquire options.merge(should_raise: false)
            return release options
          else
            return raise_or_false options, NotReleasedError
          end

        else
          self.released = true
          self.acquired = false
          driver.remove options
          return true
        end
      end

    end
  end
end
