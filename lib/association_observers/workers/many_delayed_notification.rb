# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    class ManyDelayedNotification < Base

      attr_reader :observer_ids, :klass, :proxy_method_name

      def initialize(observer_ids, klass_name, proxy_method_name)
        @observer_ids = observer_ids
        @klass = klass_name
        @proxy_method_name = proxy_method_name
      end

      def perform
        observers = AssociationObservers::orm_adapter.find_all(@klass.constantize, :id => @observer_ids)

        observers.each(&remote_queue.send(@proxy_method_name))
        # after we are down, we are going to delete the proxy method name
        remote_queue.send :unregister_auxiliary_method, @proxy_method_name
      end


      private

      def remote_queue
        DRbObject.new_with_uri(AssociationObservers::options[:queue_drb_location])
      end

    end
  end

end