# -*- encoding : utf-8 -*-
require "association_observers/orm/base"

module AssociationObservers
  module Orm
    class ActiveRecord < Base
      def self.find(klass, primary_key)
        klass.find_by_id(primary_key)
      end

      # @see AssociationObservers::Orm::Base.find_all
      def self.find_all(klass, attributes)
        klass.send("find_all_by_#{attributes.keys.join('_and_')}", *attributes.values)
      def self.key(klass)
        klass.primary_key
      end

      # @see AssociationObservers::Orm::Base.get_field
      def self.get_field(collection, attrs={})
        collection.is_a?(::ActiveRecord::Relation) or collection.respond_to?(:proxy_association) ?
        collection.limit(attrs[:limit]).offset(attrs[:offset]).pluck(*attrs[:fields].map{|attr| "#{collection_class(collection).arel_table.name}.#{attr}" }) :
        super
      end

      # @see AssociationObservers::Orm::Base.collection_class
      def self.collection_class(collection)
        collection.klass
      end

      # @see AssociationObservers::Orm::Base.class_variable_set
      def self.class_variable_set(klass, name)
        klass.cattr_accessor name
      end

      # @see AssociationObservers::Orm::Base.batched_each
      def self.batched_each(collection, batch, &block)
        if collection.is_a?(::ActiveRecord::Relation) ?
           collection.find_each(:batch_size => batch, &block) :
           super
        end
      end

    # @see AssociationObservers::Orm::Base.validate_parameters
      def self.validate_parameters(observer, observable_associations, notifier_names, callbacks)
        raise "Invalid callback; possible options: :create, :update, :save, :destroy" unless callbacks.all?{|o|[:create,:update,:save,:destroy].include?(o.to_sym)}
      end
    end
  end
end

