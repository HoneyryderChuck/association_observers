# -*- encoding : utf-8 -*-

module AssociationObservers
  module ResqueWorkerExtensions
    def self.included(base)
      base.class_eval do
        @queue = AssociationObservers::options[:queue].to_sym
      end
      extend ClassMethods
    end

    module ClassMethods

      def perform(*args)
        self.new(*args).perform
      end
    end
  end

  module ResqueQueueExtensions
    private

    def enqueue(task, *args)
      Resque.enqueue(task, *args)
    end
  end
end

