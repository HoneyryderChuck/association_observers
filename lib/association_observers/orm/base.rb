# -*- encoding : utf-8 -*-
module AssociationObservers
  module Orm
    class Base

      def self.key(klass)
        raise "should be defined in an adapter for the used ORM"
      end

      # finds record by primary key
      # @abstract
      #
      # @param [Class] klass the class of the record to look for
      # @param [Object] primary_key primary key of the record to look for
      # @return [Symbol] ORM class method that fetches records from the DB
      def self.find(klass, primary_key)
        klass.to_adapter.get(primary_key)
      end

      # finds all records which match the given attributes
      # @abstract
      #
      # @param [Class] klass the class of the records to look for
      # @param [Hash] attributes list of key/value associations which have to be matched by the found records
      # @return [Symbol] ORM class method that fetches records from the DB
      def self.find_all(klass, attributes)
        klass.to_adapter.find_all(attributes)
      end

      # @param [Array] collection records to iterate through
      # @param [Array] attrs attributes to fetch for
      # @return [Array] a collection of the corresponding values to the given keys for each record
      def self.get_field(collection, attrs)
        attrs[:offset] == 0 ? collection.map{|elem| elem.send(*attrs[:fields])} : []
      end

      # @abstract
      # @param [Array] collection objects container
      # @return [Symbol] ORM collection method name to get the model of its children
      def self.collection_class(collection)
        raise "should be defined in an adapter for the used ORM"
      end

      # implementation of a batched each enumerator on a collection
      #
      # @param [Array] collection records to batch through
      def self.batched_each(collection, batch=1, &block)
        batch > 1 ?
        collection.each_slice(batch) { |batch| batch.each(&block) } :
        collection.each(&block)
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