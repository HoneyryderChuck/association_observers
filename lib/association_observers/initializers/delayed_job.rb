# -*- encoding : utf-8 -*-

module AssociationObservers
  class Queue
    private

    def enqueue(task, *args)
      job = task.new(*args)
      Delayed::Job.enqueue job
    end
  end
end