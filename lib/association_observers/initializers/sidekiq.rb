# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers


    class ManyDelayedNotification
      include Sidekiq::Worker

      def initialize ; ; end

      alias :perform_action! :perform

      def perform(observer_ids, klass, proxy_method_name)
        @observer_ids = observer_ids
        @klass = klass
        @proxy_method_name = proxy_method_name
        perform_action!
      end

    end
  end

  class Queue
    private

    def enqueue(task, *args)
      task.perform_async(*args)
    end
  end
end

