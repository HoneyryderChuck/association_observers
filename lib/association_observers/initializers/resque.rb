# -*- encoding : utf-8 -*-

module AssociationObservers
  module Workers

    class ManyDelayedNotification
      @queue = AssociationObservers::default_options[:queue].to_sym

      def self.perform(*args)
        self.new(*args).perform
      end
    end
  end

  class Queue
    private

    def enqueue(task, *args)
      Resque.enqueue(task, *args)
    end
  end
end

