module Mongo
  class Lock
    module SendWithRaise

      def send_with_raise method, *args
        args.last[:should_raise] = true
        self.send(method, *args)
      end

      def acquire! options = {}, &block
        send_with_raise :acquire, options, &block
      end

      def release! options = {}, &block
        send_with_raise :release, options, &block
      end

      def extend_by! time, options = {}, &block
        send_with_raise :extend_by, time, options, &block
      end

      def extend! options = {}, &block
        send_with_raise :extend, options, &block
      end

    end
  end
end
