# -*- encoding : utf-8 -*-
module AssociationObservers
  #module Workers
  #  class ManyDelayedNotification
  #    include Sidekiq::Worker
  #
  #    sidekiq_options :queue => AssociationObservers::options[:queue][:name].to_sym
  #
  #    alias :perform_action! :perform
  #    alias :standard_initialize :initialize
  #
  #    def initialize ; ; end
  #
  #    def perform(*args)
  #      standard_initialize(*args)
  #      # notifier has been dumped two times, reset it here
  #      @notifier = args.last
  #      perform_action!
  #    end
  #  end
  #end

  class Queue
    private

    def load_sidekiq_engine
      # pimp my #enqueue
      instance_eval do
        alias :enqueue_without_sidekiq :enqueue
        alias :enqueue :enqueue_with_sidekiq
      end

      # pimp my worker
      worker_class = AssociationObservers::Workers::ManyDelayedNotification
      worker_class.send :include, Sidekiq::Worker
      worker_class.sidekiq_options :queue => AssociationObservers::options[:queue][:name].to_sym
      worker_class.send :alias_method, :perform_action!, :perform
      worker_class.send :alias_method, :standard_initialize, :initialize
      worker_class.send :define_method, :initialize do ; ; end
      worker_class.send :define_method, :perform do |*args|
        standard_initialize(*args)
        @notifier = args.last
        perform_action!
      end

    end

    def unload_sidekiq_engine
      # unpimp my enqueue
      instance_eval do
        alias :enqueue_with_sidekiq :enqueue
        alias :enqueue :enqueue_without_sidekiq
      end

      # unpimp my worker
      worker_class = AssociationObservers::Workers::ManyDelayedNotification
      # TODO: how to remove Sidekiq::Worker module?
      worker_class.send :alias_method, :perform, :perform_action!
      worker_class.send :alias_method, :initialize, :standard_initialize
    end

    # overwriting of the method. Sidekiq workers use a method called perform_async
    def enqueue_with_sidekiq(task, *args)
      task.perform_async(*args[0..-2] << Marshal.dump(args.last))
    end
  end
end

