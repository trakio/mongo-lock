module Mongo
  class Lock
    module ConvenienceMethods

      def init_and_send key, options = {}, method, &block
        lock = Mongo::Lock.new(key, options)
        lock.send(method, &block)
        lock
      end

      def acquire key, options = {}, &block
        init_and_send key, options, :acquire, &block
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
        Mongo::Lock.new(key, options).available?
      end

    end
  end
end
