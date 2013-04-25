# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    # This is our main batched worker. It helps on the task of queueing batches of records and asynchronously
    # call the notifier conditional action for each of them.
    class ManyDelayedNotification

      attr_reader :observer_ids, :observer_klass, :observable_id, :observable_klass, :notifier

      # @param [Array] observer_ids array of ids of the observers which are going to be iterated
      # @param [String] observer_klass the class of the observers
      # @param [Integer, String] observable_id if of the observable
      # @param [String] observable_klass the class of the observable
      # @param [String] notifier the notifier containing the action in marshalled format
      def initialize(observer_ids, observer_klass, observable_id, observable_klass, notifier)
        @observer_ids = observer_ids
        @observer_klass = observer_klass
        @observable_id = observable_id
        @observable_klass = observable_klass
        @notifier = Marshal.dump(notifier)
      end

      # Here we execute our task:
      # 1. Unmarshal notifier, get observable
      # 2. Load all the observers
      # 3. Iterate over them and execute the notifier #conditional_action, which takes the observer and the observable as parameters
      def perform
        observable = AssociationObservers::orm_adapter.find(@observable_klass.constantize, @observable_id)
        return if observable.nil?
        notifier = Marshal.load(@notifier)
        method = RUBY_VERSION < "1.9" ?
            AssociationObservers::Backports::Proc.fake_curry(notifier.method(:conditional_action).to_proc, observable) :
            notifier.method(:conditional_action).to_proc.curry[observable]
        AssociationObservers::orm_adapter.find_all(@observer_klass.constantize, :id => @observer_ids).each(&method)
      end


    end
  end

end