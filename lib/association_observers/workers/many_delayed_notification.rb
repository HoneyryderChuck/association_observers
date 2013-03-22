# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    class ManyDelayedNotification

      attr_reader :callback, :observer_ids, :klass

      def initialize(callback, observer_ids, klass)
        @callback = callback
        @observer_ids = observer_ids
        @klass = klass.name
      end

      def perform
        observers = AssociationObservers.find(@klass, :id => @observer_ids)
        observers.each(&action)
      end

    end
  end

end