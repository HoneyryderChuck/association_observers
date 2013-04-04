# -*- encoding : utf-8 -*-
if defined?(DataMapper)
  module AssociationObservers
    module Orm
      autoload :DataMapper, "association_observers/orm/data_mapper"
    end

    def self.orm_adapter
      @orm_adapter ||= Orm::DataMapper
    end

    module IsObservableMethods
      def self.included(model)
        model.extend(ClassMethods)
        model.send :include, InstanceMethods
      end

      module ClassMethods
        def notifiers
          @notifiers ||= []
        end
        private

        def set_observers(ntfs, callbacks, observer_class, association_name, observable_association_name)
          ntfs.each do |notifier|
            callbacks.each do |callback|
              options = {} # todo: use this for polymorphics
              observer_association = self.relationships[association_name]||
                                     self.relationships[association_name.pluralize]

              options[:observable_association_name] = observable_association_name

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

      module InstanceMethods


        private


        def notify_observers(args)
          self.class.notifiers.each{|notifier| notifier.update(args, self)}
        end
      end
    end

    module IsObserverMethods

      module ClassMethods

        private

        def observer_extensions
          #include DataMapper::Observer
        end

        def get_association_options_pairs(association_names)
          # TODO: find better way to figure out the class of the relationship entity
          relationships.select{|r|association_names.include?(r.name)}.map{|r| [r.name, (r.is_a?(DataMapper::Associations::ManyToOne::Relationship) ? r.parent_model : r.child_model), r.options] }
        end

        def filter_collection_associations(associations)
          associations.select{ |arg| self.relationships[arg].options[:max] == Infinity }
        end

        def define_collection_callback_routines(callbacks, notifiers)
          callbacks
        end

        def redefine_collection_associations_with_collection_callbacks(associations, callbacks)
          associations.each do |assoc|
            callbacks.each do |callback|
              relationship = relationships[assoc]
              model_method = relationship.is_a?(DataMapper::Associations::ManyToOne::Relationship ) ?
                             :parent_model :
                             :child_model
              relationship.send(model_method).after callback do
                notify! callback
              end
            end
          end
        end

      end
    end
  end


  DataMapper::Model.append_inclusions AssociationObservers
end