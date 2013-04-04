# -*- encoding : utf-8 -*-

module AssociationObservers
  module DelayedJobWorkerExtensions

  end
  module DelayedJobQueueExtensions
    private

    def enqueue(task, *args)
      job = task.new(*args)
      Delayed::Job.enqueue job
    end
  end
end