# -*- encoding : utf-8 -*-
require 'singleton'

# the queue handles the notification distributions which the notifiers trigger. The Notifier usually knows what to notify
# and whom to notify. It passes this information to the queue, which strategizes the dispatching. It is more than a singleton;
# it is designed as a single inter-process object. Why? Because one cannot marshall procedures, and this unique inter-process
# object acts as a container for the procedures which will be handled assynchronously by the message queue solution. It is also
# a proxy to the used background queue solution: the queueing basically proxies the queueing somewhere else (Delayed Job, Resque...)
module AssociationObservers
  class Queue
    include Singleton


    # encapsulates enqueuing strategy. if the callback is to a destroy action, one cannot afford to enqueue, because the
    # observable will be deleted by then. So, perform destroy notifications synchronously right away. If not, the strategy
    # for now is get the object ids and enqueue them with the notifier.
    #
    # @param [ActiveRecord:Relation, DataMapper::Relationship] observers to be notified
    # @param [Notifier::Base] notifier encapsulates the notification logic
    # @param [Hash] opts other possible options that can't be inferred from the given arguments
    def enqueue_notifications(observers, observable, notifier, opts={})
      klass       = opts[:klass]      || AssociationObservers::orm_adapter.collection_class(observers)
      batch_size  = opts[:batch_size] || klass.observable_options[:batch_size]

      if notifier.callback.eql?(:destroy)
        method = RUBY_VERSION < "1.9" ?
            AssociationObservers::Backports::Proc.fake_curry(notifier.method(:conditional_action).to_proc, observable) :
            notifier.method(:conditional_action).to_proc.curry[observable]
        AssociationObservers::orm_adapter.batched_each(observers, batch_size, &method)
      else
        # create workers
        i = 0
        loop do
          ids = AssociationObservers::orm_adapter.get_field(observers, :fields => [AssociationObservers::orm_adapter.key(klass)], :limit => batch_size, :offset => i*batch_size).compact
          break if ids.empty?
          enqueue(Workers::ManyDelayedNotification, ids, klass.name, observable.id, observable.class.name, notifier)
          i += 1
        end
      end
    end

    def engine
      AssociationObservers::options[:queue][:engine]
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
      load_engine
    end

    def finalize_engine
      unload_engine
      AssociationObservers::options[:queue][:engine] = nil
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

    def load_engine
      send("load_#{engine}_engine") unless engine.nil?
    end

    def unload_engine
      send("unload_#{engine}_engine") unless engine.nil?
    end

  end
end
