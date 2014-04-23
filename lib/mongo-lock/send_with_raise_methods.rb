module Mongo
  class Lock
    module SendWithRaiseMethods

      def send_with_raise method, *args
        args.last[:should_raise] = true
        self.send(method, *args)
      end

      def acquire! options = {}
        send_with_raise :acquire, options
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
