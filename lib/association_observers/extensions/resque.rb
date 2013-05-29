# -*- encoding : utf-8 -*-

module AssociationObservers
  class Queue
    private

    def load_resque_engine
      # pimp my #enqueue
      instance_eval do
        alias :enqueue_without_resque :enqueue
        alias :enqueue :enqueue_with_resque
      end

      # pimp my worker
      worker_class = AssociationObservers::Workers::ManyDelayedNotification
      worker_class.instance_variable_set("@queue", AssociationObservers::options[:queue][:name].to_sym)
      worker_class.send :alias_method, :standard_initialize, :initialize
      worker_class.send :define_method, :initialize do |*args|
        standard_initialize(*args)
        # notifier has been dumped two times, reset it here
        @notifier = args.last
      end
      worker_class.class_eval do
        def self.perform(*args)
          self.new(*args).perform
        end
      end
    end

    def unload_resque_engine
      # unpimp my enqueue
      instance_eval do
        alias :enqueue_with_resque :enqueue
        alias :enqueue :enqueue_without_resque
      end

      # unpimp my worker
      worker_class = AssociationObservers::Workers::ManyDelayedNotification
      worker_class.instance_variable_set("@queue", nil)
      worker_class.send :alias_method, :initialize, :standard_initialize
      # TODO: how to remove class method perform?
    end

    # overwriting of the enqueue method, using the Resque enqueue method already
    def enqueue_with_resque(task, *args)
      ::Resque.enqueue(task, *args[0..-2] << Marshal.dump(args.last))
    end
  end
end

