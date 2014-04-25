module Mongo
  class Lock
    module SendWithRaise

      def send_with_raise method, *args, &block
        args.last[:should_raise] = true
        self.send(method, *args, &block)
      end

      def acquire! options = {}, &block
        send_with_raise :acquire, options, &block
      end

      def release! options = {}
        send_with_raise :release, options
      end

      def extend_by! time, options = {}
        send_with_raise :extend_by, time, options
      end

      def extend! options = {}
        send_with_raise :extend, options
      end

    end
  end
end
