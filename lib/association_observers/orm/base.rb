# -*- encoding : utf-8 -*-
module AssociationObservers
  module Orm
    class Base
      # @abstract
      # @return [Symbol] ORM class method that fetches records from the DB
      def self.find_all(klass, attributes)
        raise "should be defined in an adapter for the used ORM"
      end

      def self.get_field(klass_or_relation, attrs)
        raise "should be defined in an adapter for the used ORM"
      end

      # @abstract
      # @return [Symbol] ORM instance method name which checks whether the record is a new instance
      def self.check_new_record_method
        raise "should be defined in an adapter for the used ORM"
      end

      # @abstract
      # @return [Symbol] ORM collection method name to get the model of its children
      def self.fetch_model_from_collection
        raise "should be defined in an adapter for the used ORM"
      end

      # @abstract
      # implementation of an ORM-specifc batched each enumerator on a collection
      def self.batched_each(collection, batch, &block)
        raise "should be defined in an adapter for the used ORM"
      end

      # @abstract
      # checks the parameters received by the observer DSL call, handles unexpected input according by triggering exceptions,
      # warnings, deprecation messages
      # @param [Class] observer the observer class
      # @param [Array] observable_associations collection of the names of associations on the observer which will be observed
      # @param [Array] notifier_classes collection of the notifiers for the observation
      # @param [Array] observer_callbacks collection of the callbacks/methods to be observed
      def self.validate_parameters(observer, observable_associations, notifier_classes, observer_callbacks)
        raise "should be defined in an adapter for the used ORM"
      end

    end
  end
end