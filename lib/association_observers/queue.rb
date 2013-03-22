# -*- encoding : utf-8 -*-
module AssociationObservers
  class Queue

    def enqueue_notifications(callback, observers, klass, batch_size, &action)
      if callback.eql?(:destroy)
        AssociationObservers::orm_adapter.batched_each(observers, batch_size, &action)
      else
        # define method in queue which delegates to the passed action
        action_copy = action.dup
        proxy_method_name = :"_aux_action_proxy_method_#{action_copy.object_id}_"
        self.class.send :define_method, proxy_method_name, lambda { action_copy }

        # create workers
        i = 0
        loop do
          ids = AssociationObservers::orm_adapter.get_field(observers, :fields => [:id], :limit => batch_size, :offset => i*batch_size)
          break if ids.empty?
          enqueue(Workers::ManyDelayedNotification, ids, klass, proxy_method_name)
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
