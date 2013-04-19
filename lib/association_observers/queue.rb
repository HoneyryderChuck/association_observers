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
    def self.remote_queue
      existing_queue = DRbObject.new_with_uri(AssociationObservers::options[:queue][:drb_location])
      begin
        existing_queue.is_alive?
        existing_queue
      rescue DRb::DRbConnError
        queue = new
        DRb.start_service(AssociationObservers::options[:queue][:drb_location], queue)
        queue
      end
    end

    # ghost method used in the registration/initialization process
    def is_alive?
      true
    end

    # encapsulates enqueuing strategy. if the callback is to a destroy action, one cannot afford to enqueue, because the
    # observable will be deleted by then. So, perform destroy notifications synchronously right away. If not, the strategy
    # for now is get the object ids and enqueue them with the notifier.
    #
    # @param [ActiveRecord:Relation, DataMapper::Relationship] observers to be notified
    # ªparam [Notifier::Base] notifier encapsulates the notification logic
    # @param [Hash] opts other possible options that can't be inferred from the given arguments
    def enqueue_notifications(observers, observable, notifier, opts={})
      klass       = opts[:klass]      || AssociationObservers::orm_adapter.collection_class(observers)
      batch_size  = opts[:batch_size] || klass.observable_options[:batch_size]

      if notifier.callback.eql?(:destroy)
        AssociationObservers::orm_adapter.batched_each(observers, batch_size, &notifier.method(:conditional_action).to_proc.curry[observable])
      else
        # create workers
        i = 0
        loop do
          ids = AssociationObservers::orm_adapter.get_field(observers, :fields => [:id], :limit => batch_size, :offset => i*batch_size).compact
          break if ids.empty?
          enqueue(Workers::ManyDelayedNotification, ids, klass.name, observable.id, observable.class.name, notifier)
          i += 1
        end
      end
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
