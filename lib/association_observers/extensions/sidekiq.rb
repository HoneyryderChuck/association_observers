# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    class ManyDelayedNotification
      include Sidekiq::Worker

      sidekiq_options :queue => AssociationObservers::options[:queue][:name].to_sym

      alias :perform_action! :perform
      alias :standard_initialize :initialize

      def initialize ; ; end

      def perform(*args)
        standard_initialize(*args)
        # notifier has been dumped two times, reset it here
        @notifier = args.last
        perform_action!
      end
    end
  end

  class Queue
    private

    # overwriting of the method. Sidekiq workers use a method called perform_async
    def enqueue(task, *args)
      task.perform_async(*args[0..-2] << Marshal.dump(args.last))
    end
  end
end

