# -*- encoding : utf-8 -*-
require 'drb/drb'
require 'singleton'

module AssociationObservers
  class Queue
    include Singleton

    def initialize
      existing_queue = DRbObject.new_with_uri(AssociationObservers::options[:queue_drb_location])
      unless existing_queue.nil?
        DRb.start_service(AssociationObservers::options[:queue_drb_location], self)
        super
      else
        existing_queue
      end
    end

    def enqueue_notifications(callback, observers, klass, batch_size, &action)
      if callback.eql?(:destroy)
        AssociationObservers::orm_adapter.batched_each(observers, batch_size, &action)
      else
        # create workers
        i = 0
        loop do
          # define method in queue which delegates to the passed action
          action_copy = action.dup
          proxy_method_name = :"_aux_action_proxy_method_#{action_copy.object_id}_"
          register_auxiliary_method(proxy_method_name, lambda { action_copy } )
          ids = AssociationObservers::orm_adapter.get_field(observers, :fields => [:id], :limit => batch_size, :offset => i*batch_size).compact
          break if ids.empty?
          enqueue(Workers::ManyDelayedNotification, ids, klass.name, proxy_method_name)
          i += 1
        end
      end
    end

    def register_auxiliary_method(name, procedure)
      self.class.send :define_method, name, procedure
    end

    def unregister_auxiliary_method(method)
      self.class.send :undef_method, method
    end

    private

    # implementation when there is no background processing queue -> execute immediately
    def enqueue(task, *args)
      t = task.new(*args)
      t.perform
    end

  end
end
