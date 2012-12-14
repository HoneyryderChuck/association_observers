# -*- encoding : utf-8 -*-
if defined?(DataMapper)
  module AssociationObservers
    def self.check_new_record_method
      :new?
    end

    def self.fetch_model_from_collection
      :model
    end

    def self.batched_each(collection, batch, &block)
      collection.each(&block) # datamapper batches already by 500 https://groups.google.com/forum/?fromgroups=#!searchin/datamapper/batches/datamapper/lAZWFN4TWAA/G1Gu-ams_QMJ
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

        def set_observers(ntfs, callbacks, observer_class, association_name)
          ntfs.each do |notifier|
            callbacks.each do |callback|
              options = {} # todo: use this for polymorphics
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

      module InstanceMethods


        private


        def notify_observers(callback)
          self.class.notifiers.each{|notifier| notifier.update(callback, self)}
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
          relationships.select{|r|association_names.include?(r.name)}.map{|r| [(r.is_a?(DataMapper::Associations::ManyToOne::Relationship ) ? r.parent_model_name : r.child_model_name).constantize, r.options] }
        end

        def filter_collection_associations(associations)
          associations.select{ |arg| self.relationships[arg].options[:max] == Infinity }
        end

        def define_collection_callback_routines(callbacks, notifiers)

        end

        def redefine_collection_associations_with_collection_callbacks(associations, callback_procs)

        end

      end
    end
  end


  DataMapper::Model.append_inclusions AssociationObservers
end