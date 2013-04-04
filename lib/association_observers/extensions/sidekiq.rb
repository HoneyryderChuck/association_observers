# -*- encoding : utf-8 -*-
module AssociationObservers
  module SidekiqWorkerExtensions

    def self.included(base)
      base.send :include, Sidekiq::Worker
      base.class_eval do
        alias :perform_action! :perform
      end
    end

    def initialize ; ; end

    def perform(observer_ids, klass, proxy_method_name)
      @observer_ids = observer_ids
      @klass = klass
      @proxy_method_name = proxy_method_name
      perform_action!
    end
  end

  module SidekiqQueueExtensions
    private

    def enqueue(task, *args)
      task.perform_async(*args)
    end
  end
end

