# -*- encoding : utf-8 -*-
require "association_observers/orm/base"

module AssociationObservers
  module Orm
    class ActiveRecord < Base
      def self.find_all(klass, attributes)
        klass.send("find_all_by_#{attributes.keys.join('_and_')}", *attributes.values)
      end

      def self.get_field(collection, attrs={})
        collection.is_a?(::ActiveRecord::Relation) ?
        collection.limit(attrs[:limit]).offset(attrs[:offset]).pluck(*attrs[:fields]) :
        super
      end

      def self.collection_class(collection)
        collection.klass
      end

      def self.class_variable_set(klass, name)
        klass.cattr_accessor name
      end

      def self.batched_each(collection, batch, &block)
        if collection.is_a?(::ActiveRecord::Relation) ?
           collection.find_each(:batch_size => batch, &block) :
           super
        end
      end

      def self.validate_parameters(observer, observable_associations, notifier_names, callbacks)
        raise "Invalid callback; possible options: :create, :update, :save, :destroy" unless callbacks.all?{|o|[:create,:update,:save,:destroy].include?(o.to_sym)}
      end
    end
  end
end

