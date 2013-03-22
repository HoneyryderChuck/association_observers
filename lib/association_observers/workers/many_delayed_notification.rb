# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    class ManyDelayedNotification

      attr_reader :observer_ids, :klass, :action

      def initialize(observer_ids, klass, action)
        @observer_ids = observer_ids
        @klass = klass.name
        @action = action
      end

      def perform
        observers = AssociationObservers::orm_adapter.find_all(@klass.constantize, :id => @observer_ids)
        observers.each(&@action)
      end

    end
  end

end