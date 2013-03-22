# -*- encoding : utf-8 -*-
module AssociationObservers
  module Workers
    class Base
      def perform
        raise "should be overwritten by subclasses"
      end
    end
  end
end