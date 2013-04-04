# -*- encoding : utf-8 -*-
require 'drb/drb'
require 'singleton'

# the queue handles the notification distributions which the notifiers trigger. The Notifier usually knows what to notify
# and whom to notify. It passes this information to the queue, which strategizes the dispatching. It is more than a singleton;
# it is designed as a single inter-process object. Why? Because one cannot marshall procedures, and this unique inter-process
# object acts as a container for the procedures which will be handled assynchronously by the message queue solution. It is also
# a proxy to the used background queue solution: the queueing basically proxies the queueing somewhere else (Delayed Job, Resque...)
module AssociationObservers
  class Queue
    include Singleton

    # it checks whether there is a queue already registered in the DRb space. If so, use it. if not, create and register
    def initialize
      existing_queue = DRbObject.new_with_uri(AssociationObservers::options[:queue][:drb_location])
      unless existing_queue.nil?
        DRb.start_service(AssociationObservers::options[:queue][:drb_location], self)
        super
      else
        existing_queue
      end
    end

    # encapsulates enqueuing strategy. if the callback is to a destroy action, one cannot afford to enqueue, because the
    # observable will be deleted by then. So, perform destroy notifications synchronously right away. If not, the strategy
    # for now is get the procedure, register it in the queue, get the object ids it refers to and enqueue this information.
    #
    # @param [Symbol] callback identifies the type of notification
    # @param [ActiveRecord:Relation, DataMapper::Relationship] observers whom to execute the procedure for
    # @param [Hash] opts other possible options that can't be inferred from the given arguments
    def enqueue_notifications(callback, observers, opts={}, &action)
      klass       = opts[:klass]      || AssociationObservers::orm_adapter.collection_class(observers)
      batch_size  = opts[:batch_size] || klass.observable_options[:batch_size]

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

    # meta-defines a method which does nothing more than return a proc
    # unfortunately, this has to be public to be available cross-process
    def register_auxiliary_method(name, procedure)
      self.class.send :define_method, name, procedure
    end

    # undefines a previously added meta-method
    # unfortunately, this has to be public to be available cross-process
    def unregister_auxiliary_method(method)
      self.class.send :undef_method, method
    end


    def engine=(engine)
      AssociationObservers::options[:queue][:engine] = engine
      initialize_queue_engine
    end

    def initialize_queue_engine
      engine = AssociationObservers::options[:queue][:engine]
      return if engine.nil?
      raise "#{engine}: unsupported engine" unless %w(delayed_job resque sidekiq).include?(engine.to_s)
      # first, remove stuff from previous engine
      # TODO: can une exclude modules???
      #if AssociationObservers::options[:queue_engine]
      #
      #end
      require "association_observers/extensions/#{engine}"
    end

    private

    # enqueues the task with the given arguments to be processed asynchronously
    # this method implements the fallback, which is: execute synchronously
    # @note this method is overwritten by the message queue adapters. If your background queue engine is not supported,
    #       overwrite this method and delegate to your background queue.
    def enqueue(task, *args)
      t = task.new(*args)
      t.perform
    end

  end
end
