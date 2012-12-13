# -*- encoding : utf-8 -*-
if defined?(ActiveRecord)

  module AssociationObservers

    module IsObservableMethods
      module ClassMethods

        private

        def set_observers(notifiers, callbacks, observer_class, association_name)
          notifiers.each do |notifier|
            callbacks.each do |callback|
              options = {}
              observer_association = self.reflect_on_association(association_name.to_sym) ||
                                     self.reflect_on_association(association_name.pluralize.to_sym)
              options[:observer_class] = observer_class.base_class if observer_association.options[:polymorphic]

              self.add_observer notifier.new(callback, observer_association.name, options)
              include "#{notifier.name}::ObservableMethods".constantize if notifier.constants.map(&:to_sym).include?(:ObservableMethods)
            end
          end
        end
      end
    end

    module IsObserverMethods

      module ClassMethods

        private

        def get_association_options_pairs(association_names)
          reflect_on_all_associations.select{ |r| association_names.include?(r.name) }.map{|r| [r.klass, r.options] }
        end

        def filter_collection_associations(associations)
          associations.select{ |arg| self.reflections[arg].collection? }
        end
      end
    end
  end



  ActiveRecord::Base.send(:include, AssociationObservers)
end