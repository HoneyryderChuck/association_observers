# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    class ManyDelayedNotification

      attr_reader :observer_ids, :observer_klass, :observable_id, :observable_klass, :notifier

      def initialize(observer_ids, observer_klass, observable_id, observable_klass, notifier)
        @observer_ids = observer_ids
        @observer_klass = observer_klass
        @observable_id = observable_id
        @observable_klass = observable_klass
        @notifier = Marshal.dump(notifier)
      end

      def perform
        observable = AssociationObservers::orm_adapter.find(@observable_klass.constantize, @observable_id)
        return if observable.nil?
        notifier = Marshal.load(@notifier)
        AssociationObservers::orm_adapter.find_all(@observer_klass.constantize, :id => @observer_ids).each(&notifier.method(:conditional_action).to_proc.curry[observable])
      end


    end
  end

end