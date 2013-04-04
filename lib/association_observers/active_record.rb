# -*- encoding : utf-8 -*-
if defined?(ActiveRecord)

  module AssociationObservers
    module Orm
      autoload :ActiveRecord, "association_observers/orm/active_record"
    end

    def self.orm_adapter
      @orm_adapter ||= Orm::ActiveRecord
    end

    # translation of AR callbacks to collection callbacks; we want to ignore the update on collections because neither
    # add nor remove shall be considered an update event in the observables
    # @example
    #   class RichMan < ActiveRecord::Base
    #     has_many :cars
    #     observes :cars, :on => :update
    #     ...
    #   end
    #
    #   in this example, for instance, the rich man wants only to be notified when the cars are update, not when he
    #   gets a new one or when one of them goes to the dumpster
    COLLECTION_CALLBACKS_MAPPER = {:create => :add, :save => :add, :destroy => :remove}

    module IsObservableMethods
      module ClassMethods

        private

        # given the fetched information, it initializes the notifiers
        # @param [Array] notifiers notifiers for the current class
        # @param [Array] callbacks valid callbacks for the notifiers
        # @param [Class] observer_class the class of the observer
        # @param [Symbol] association_name the observer identifier on the observable
        def set_observers(notifiers, callbacks, observer_class, association_name, observable_association_name)
          notifiers.each do |notifier|
            callbacks.each do |callback|
              options = {}
              observer_association = self.reflect_on_association(association_name.to_sym) ||
                                     self.reflect_on_association(association_name.pluralize.to_sym)
              options[:observer_class] = observer_class.base_class if observer_association.options[:polymorphic]

              options[:observable_association_name] = observable_association_name

              self.add_observer notifier.new(callback, observer_association.name, options)
              include "#{notifier.name}::ObservableMethods".constantize if notifier.constants.map(&:to_sym).include?(:ObservableMethods)
            end
          end
        end

        def set_notification_on_callbacks(callbacks)
          callbacks.each do |callback|
            if [:create, :update].include?(callback)
              real_callback = :save
              callback_opts = {:on => callback}
            else
              real_callback = callback
              callback_opts = {}
            end
            send("after_#{real_callback}", callback_opts) do
              notify! callback
            end
          end
        end
      end
    end

    module IsObserverMethods

      module ClassMethods

        private

        def get_association_options_pairs(association_names)
          reflect_on_all_associations.select{ |r| association_names.include?(r.name) }.map{|r| [r.name, r.klass, r.options] }
        end

        def filter_collection_associations(associations)
          associations.select{ |arg| self.reflections[arg].collection? }
        end

        def define_collection_callback_routines(callbacks, notifiers)
          callbacks.map do |callback|
            notifiers.map do |notifier|
              routine_name = :"__observer_#{callback}_callback_for_#{notifier.name.demodulize.underscore}__"
              class_eval <<-END
                def #{routine_name}(element)
                  callback = element.class.observer_instances.detect do |notifier|
                    notifier.class.name == '#{notifier}' and notifier.callback == :#{callback}
                  end
                  callback.notify(element, [self]) unless callback.nil?
                end
                private :#{routine_name}
              END
              [callback, routine_name]
            end
          end.flatten(1)
        end

        def redefine_collection_associations_with_collection_callbacks(associations, callback_procs)
          associations.each do |assoc|
            a = self.reflect_on_association(assoc)
            callbacks = Hash[callback_procs.group_by{|code, proc| COLLECTION_CALLBACKS_MAPPER[code] }.reject{|k, v| k.nil? }.map{ |code, val| [:"after_#{code}", val.map(&:last)] }]
            next if callbacks.empty? # no callbacks, no need to redefine association

            # this snippet takes care that the array of callbacks which will get inserted in the association will not
            # overwrite whatever callbacks you may have already defined
            callbacks.each do |callback, procedures|
              callbacks[callback] += Array(a.options[callback])
            end

            # bullshit ruby 1.8 can't stringify hashes, arrays, symbols nor strings correctly
            if RUBY_VERSION < "1.9"
              assoc_options = AssociationObservers::Backports::extended_to_s(a.options)
              callback_options = AssociationObservers::Backports::extended_to_s(callbacks)
            else
              assoc_options = a.options.to_s
              callback_options = callbacks
            end

            class_eval <<-END
              #{a.macro} :#{assoc}, #{assoc_options}.merge(#{callback_options})
            END
          end
        end
      end
    end
  end



  ActiveRecord::Base.send(:include, AssociationObservers)
end