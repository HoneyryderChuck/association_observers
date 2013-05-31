# -*- encoding : utf-8 -*-
require "association_observers/orm/base"

module AssociationObservers
  module Orm
    def self.data_mapper?(klass=nil)
      defined?(::DataMapper) and (klass.nil? or klass.ancestors.include?((::DataMapper::Resource)))
    end

    class DataMapper < Base

      def self.key(klass)
        klass.key.first.name
      end

      # @see AssociationObservers::Orm::Base.get_field
      def self.get_field(collection, attrs={})
        collection.is_a?(::DataMapper::Collection) ?
        collection.all(attrs) :
        super
      end

      # @see AssociationObservers::Orm::Base.collection_class
      def self.collection_class(collection)
        collection.model
      end

      # @see AssociationObservers::Orm::Base.class_variable_set
      def self.class_variable_set(klass, name)
        klass.instance_eval <<-END
          @@#{name}=nil
          def #{name}
            @@#{name}
          end

          def #{name}=(value)
            @@#{name} = value
          end
        END

      end

      # @see AssociationObservers::Orm::Base.batched_each
      def self.batched_each(collection, batch, &block)
        collection.is_a?(::DataMapper::Collection) ?
        collection.each(&block) : # datamapper batches already by 500 https://groups.google.com/forum/?fromgroups=#!searchin/datamapper/batches/datamapper/lAZWFN4TWAA/G1Gu-ams_QMJ
        super
      end

      # @see AssociationObservers::Orm::Base.validate_parameters
      def self.validate_parameters(observer, observable_associations, notifier_names, callbacks)
        observable_associations.each do |o|
          if observer.relationships[o].is_a?(::DataMapper::Associations::ManyToMany::Relationship)
            warn "this gem does not currently support observation behaviour for many to many relationships"
          end
        end
      end
    end
  end
end

