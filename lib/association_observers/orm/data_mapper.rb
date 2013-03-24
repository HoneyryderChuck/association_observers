# -*- encoding : utf-8 -*-
require "association_observers/orm/base"

module AssociationObservers
  module Orm
    class DataMapper < Base
      def self.find_all(klass, attributes)
        klass.all(attributes)
      end

      def self.get_field(collection, attrs={})
        collection.is_a?(::DataMapper::Associations::Relationship) ?
        collection.all(attrs) :
        super
      end

      def self.fetch_model_from_collection
        :model
      end

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

      def self.batched_each(collection, batch, &block)
        collection.is_a?(::DataMapper::Associations::Relationship) ?
        collection.each(&block) : # datamapper batches already by 500 https://groups.google.com/forum/?fromgroups=#!searchin/datamapper/batches/datamapper/lAZWFN4TWAA/G1Gu-ams_QMJ
        super
      end

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

