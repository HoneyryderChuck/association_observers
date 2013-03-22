# -*- encoding : utf-8 -*-
module AssociationObservers
  class Queue

    def enqueue_notifications(callback, observers, klass, batch_size, &action)
      if callback.eql?(:destroy)
        AssociationObservers::orm_adapter.batched_each(observers, batch_size, &action)
      else
        i = 1
        loop do
          ids = AssociationObservers::orm_adapter.get_field(observers, :fields => [:id], :limit => batch_size, :offset => i*batch_size)
          break if ids.empty?
          enqueue(ManyDelayedNotification, callback, ids, klass, action)
          i += 1
        end
      end
    end

    def enqueue(task, callback, *args)
      if callback.eql?(:destroy)
        task.new(*args)
        t.perform
      else
        # enqueue later
        t.perform
      end
    end

  end
end
