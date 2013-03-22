# -*- encoding : utf-8 -*-
require "association_observers/orm/base"

module AssociationObservers
  module Orm
    class ActiveRecord < Base
      def self.find(klass, attributes)
        klass.send("find_by_#{attributes.keys.join('_and_')}", *attributes.values)
      end

      def self.get_field(klass, attrs={})
        klass.limit(attrs[:limit]).offset(attrs[:offset]).pluck(*attrs[:fields])
      end

      def self.check_new_record_method
        :new_record?
      end

      def self.fetch_model_from_collection
        :klass
      end

        def self.class_variable_set(klass, name)
          klass.cattr_accessor name
        end

      def self.batched_each(collection, batch, &block)
        collection.find_each(:batch_size => batch, &block)
      end

      def self.validate_parameters(observer, observable_associations, notifier_names, callbacks)
        raise "Invalid callback; possible options: :create, :update, :save, :destroy" unless callbacks.all?{|o|[:create,:update,:save,:destroy].include?(o.to_sym)}
      end
    end
  end
end

