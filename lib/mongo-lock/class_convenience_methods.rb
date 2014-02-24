module Mongo
  class Lock
    module ClassConvenienceMethods

      def init_and_send key, options = {}, method
        lock = Mongo::Lock.new(key, options)
        lock.send(method)
        lock
      end

      def acquire key, options = {}
        init_and_send key, options, :acquire
      end

      def release key, options = {}
        init_and_send key, options, :release
      end

      def acquire! key, options = {}
        init_and_send key, options, :acquire!
      end

      def release! key, options = {}
        init_and_send key, options, :release!
      end

      def available? key, options = {}
        init_and_send key, options, :available?
      end

    end
  end
end
