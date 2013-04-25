# -*- encoding : utf-8 -*-

module AssociationObservers
  class Queue
    private

    # overwriting the enqueue method. Delayed Job enqueues the jobs already itself
    def enqueue(task, *args)
      job = task.new(*args)
      Delayed::Job.enqueue job, :queue => AssociationObservers::options[:queue][:name], :priority => AssociationObservers::options[:queue][:priority] || Delayed::Worker.default_priority
    end
  end
end