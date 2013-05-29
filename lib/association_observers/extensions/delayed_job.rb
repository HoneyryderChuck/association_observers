# -*- encoding : utf-8 -*-

module AssociationObservers
  class Queue
    private

    def load_delayed_job_engine
      instance_eval do
        alias :enqueue_without_delayed_job :enqueue
        alias :enqueue :enqueue_with_delayed_job
      end
    end

    def unload_delayed_job_engine
      instance_eval do
        alias :enqueue_with_delayed_job :enqueue
        alias :enqueue :enqueue_without_delayed_job
      end
    end

    # overwriting the enqueue method. Delayed Job enqueues the jobs already itself
    def enqueue_with_delayed_job(task, *args)
      job = task.new(*args)
      ::Delayed::Job.enqueue job, :queue => AssociationObservers::options[:queue][:name], :priority => AssociationObservers::options[:queue][:priority] || Delayed::Worker.default_priority
    end
  end
end