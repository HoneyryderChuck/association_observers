# -*- encoding : utf-8 -*-
if defined?(DataMapper)
  module AssociationObservers

    module IsObservableMethods
      def self.included(model)
        model.extend(ClassMethods)
        model.instance_eval do
          @@notifiers ||= []
        end
      end

      module ClassMethods
        private

        def set_observers(notifiers, callbacks, observer_class, association_name)
          notifiers.each do |notifier|
            callbacks.each do |callback|
              options = {} # todo: use this for polymorphics
              notifiers = class_variable_get(:@@notifiers)
              observer_association = self.relationships[association_name]||
                                     self.relationships[association_name.pluralize]
              notifiers << notifier.new(callback, observer_association.name, options)
              include "#{notifier.name}::ObservableMethods".constantize if notifier.constants.map(&:to_sym).include?(:ObservableMethods)
            end
          end
        end

        def set_notification_on_callbacks(callbacks)
          callbacks.each do |callback|
            after callback do
              notify! callback
            end
          end
        end
      end
    end

    module IsObserverMethods

      module ClassMethods

        private

        def observer_extensions
          include DataMapper::Observer
        end

        def get_association_options_pairs(association_names)
          relationships.select{|r|association_names.include?(r.name)}.map{|r| [r.child_model_name.constantize, r.options] }
        end

        def filter_collection_associations(associations)
          associations.select{ |arg| self.relationships[arg].options[:max] == Infinity }
        end
      end
    end
  end


  DataMapper::Model.append_inclusions AssociationObservers
end