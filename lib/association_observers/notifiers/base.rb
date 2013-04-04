# -*- encoding : utf-8 -*-
module Notifier
  class Base
    attr_reader :callback, :observers, :options
    # @param [Symbol] callback callback key to which this observer will respond (:create, :update, :save, :destroy)
    # @param [Array] observers list of observers asssociations in the symbolized-underscored form (SimpleAssociation => :simple_association)
    # @param [Hash] options additional options for the notifier
    # @option options [Class] :observer_class the class of the observer (important when the observer association is polymorphic)
    def initialize(callback, observers, options = {})
      @callback = callback
      @observers = Array(observers)
      @options = options
    end


    # this function will be triggered by the notify_observers call on the observable model. It is basically
    # implemented as a filter where it is seen if the triggered callback corresponds to the callback this observer
    # responds to
    #
    # @param [Symbol] callback key from the callback that has just been triggered
    # @param [Object] observable the object which triggered the callback
    def update(callback, observable)
      return unless callback == @callback
      observers = @options.has_key?(:observer_class) ? self.observers.select{|assoc| observable.association(assoc).klass == @options[:observer_class] } : self.observers
      notify(observable, observers.map{|assoc| observable.send(assoc)}.compact)
    end

    # @return [Boolean] whether the action should be executed for the observer
    def conditions(observable, observer) ; true ; end
    # @return [Boolean] whether the action should be executed for the observers collection
    def conditions_many(observable, observers) ; true ; end

    # abstract action; has to be implemented by the subclass
    def action(observable, observer, callback=@callback)
      raise "this has to be implemented in your notifier"
    end



    private

    # Notifies all observers; filters the observers into two groups: one-to-many and one-to-one collections
    # @param [Object] observable the object which is notifying
    # @param [Array] observers the associated observers which will be notified
    def notify(observable, observers, &block)
      many, ones = observers.partition{|obs| obs.respond_to?(:size) }
      action = block_given? ? block : method(:action)
      notify_many(observable, many, &action)
      notify_ones(observable, ones, &action)
    end

    # TODO: make this notify private as soon as possible again
    public :notify

    # Abstract Method (can be re-defined by other notifiers); here it is defined the default implementation of
    # handling of many-to-many observers: for each one it will notify its observers, in case these are observed
    # @param [Object] observable the object which is notifying
    # @param [Array[ActiveRecord::Relation]] many_observers the observers which will be notified; each element represents a one-to-many relation
    def notify_many(observable, many_observers)
      many_observers.each do |observers|
        AssociationObservers::queue.enqueue_notifications(@callback, observers) do |observer|
          yield(observable, observer) if conditions(observable, observer)
        end if conditions_many(observable, observers)
      end
    end

    # Abstract Method (can be re-defined by other notifiers); here it is defined the default implementation of
    # handling of one-to-one observers: for each one it will notify its observers, in case these are observed
    # @param [Object] observable the object which is notifying
    # @param [Array[Object]] observers the observers which will be notified; each element represents a one-to-one association
    def notify_ones(observable, observers)
      observers.each do |uniq_observer|
        AssociationObservers::queue.enqueue_notifications(@callback, [uniq_observer], :batch_size => 1, :klass => uniq_observer.class) do |observer|
          yield(observable, observer)
        end if conditions(observable, uniq_observer)
      end
    end
  end
end