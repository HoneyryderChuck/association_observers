# -*- encoding : utf-8 -*-
module AssociationObservers
  class Queue

    def enqueue_notifications(callback, observers, klass, batch_size, &action)
      if callback.eql?(:destroy)
        AssociationObservers::orm_adapter.batched_each(observers, batch_size, &action)
      else
        i = 0
        loop do
          ids = AssociationObservers::orm_adapter.get_field(observers, :fields => [:id], :limit => batch_size, :offset => i*batch_size)
          break if ids.empty?
          enqueue(Workers::ManyDelayedNotification, ids, klass, action)
          i += 1
        end
      end
    end

    private

    # implementation when there is no background processing queue -> execute immediately
    def enqueue(task, *args)
      t = task.new(*args)
      t.perform
    end

  end
end
