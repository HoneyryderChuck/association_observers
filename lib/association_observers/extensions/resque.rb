# -*- encoding : utf-8 -*-

module AssociationObservers
  module Workers
    class ManyDelayedNotification
      @queue = AssociationObservers::options[:queue][:name].to_sym

      alias :standard_initialize :initialize
      def initialize(*args)
        standard_initialize(*args)
        # notifier has been dumped two times, reset it here
        @notifier = args.last
      end

      def self.perform(*args)
        self.new(*args).perform
      end
    end
  end

  class Queue
    private

    # overwriting of the enqueue method, using the Resque enqueue method already
    def enqueue(task, *args)
      Resque.enqueue(task, *args[0..-2] << Marshal.dump(args.last))
    end
  end
end

