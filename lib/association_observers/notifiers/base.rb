# -*- encoding : utf-8 -*-
module Notifier
  class Base
    attr_reader :callback, :observers, :options
    # @overload initialize(callback, observers, options)
    #   Initializes a usable notifier
    #   @param [Symbol] callback callback key to which this observer will respond (:create, :update, :save, :destroy)
    #   @param [Array] observers list of observers asssociations in the symbolized-underscored form (SimpleAssociation => :simple_association)
    #   @param [Hash] options additional options for the notifier
    #   @option options [Class] :observer_class the class of the observer (important when the observer association is polymorphic)
    # @overload initialize
    #   Initializes a ghost notifier for idempotent method extraction purposes
    def initialize(*args)
      @options = args.extract_options!
      raise "something is wrong, the notifiers was wrongly initialized" unless args.size == 0 or args.size == 2
      @callback, @observers = args
      @observers = Array(@observers)
    end


    # this function will be triggered by the notify_observers call on the observable model. It is basically
    # implemented as a filter where it is seen if the triggered callback corresponds to the callback this observer
    # responds to
    #
    # @param [Array] args [callback: key from the callback that has just been triggered, to_exclude: list of associations to exclude from the notifying chain]
    # @param [Object] observable the object which triggered the callback
    def update(args, observable)
      callback, to_exclude = args
      return unless accepted_callback?(callback)
      observers = self.observers
      observers = observers.reject{|assoc| to_exclude.include?(assoc) }
      observers = observers.select{|assoc| observable.association(assoc).klass == @options[:observer_class] } if @options.has_key?(:observer_class)
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

    # helper method which checks whether the given callback is compatible with the notifier callback.
    # Example: if the notifier is marked for :save, then :create is a valid callback.
    #          if the notifier is marked for :update, then :create is not a valid callback.
    def accepted_callback?(callback)
      case @callback
        when :save then [:create, :update, :save].include?(callback)
        when :update then [:update, :save].include?(callback)
        else callback == @callback
      end
    end

    # Notifies all observers; filters the observers into two groups: one-to-many and one-to-one collections
    # @param [Object] observable the object which is notifying
    # @param [Array] observers the associated observers which will be notified
    def notify(observable, observers)
      many, ones = observers.partition{|obs| obs.respond_to?(:size) }
      notify_many(observable, many)
      notify_ones(observable, ones)
    end

    # TODO: make this notify private as soon as possible again
    public :notify

    # Abstract Method (can be re-defined by other notifiers); here it is defined the default implementation of
    # handling of many-to-many observers: for each one it will notify its observers, in case these are observed
    # @param [Object] observable the object which is notifying
    # @param [Array[ActiveRecord::Relation]] many_observers the observers which will be notified; each element represents a one-to-many relation
    def notify_many(observable, many_observers)
      many_observers.each do |observers|
        AssociationObservers::queue.enqueue_notifications(observers, observable, self) if conditions_many(observable, observers)
      end
    end

    # Abstract Method (can be re-defined by other notifiers); here it is defined the default implementation of
    # handling of one-to-one observers: for each one it will notify its observers, in case these are observed
    # @param [Object] observable the object which is notifying
    # @param [Array[Object]] observers the observers which will be notified; each element represents a one-to-one association
    def notify_ones(observable, observers)
      observers.each do |uniq_observer|
        AssociationObservers::queue.enqueue_notifications([uniq_observer], observable, self,
                                                          :batch_size => 1, :klass => uniq_observer.class)
      end
    end

    # conditionally executes the notifier action. This is explicitly here so that its call can be queued and
    # the background worker can call it. I don't like it, but it was decided this way because we can't marshal
    # procs, therefore we can't pass procs to the workers. It is a necessary evil.
    def conditional_action(observable, observer)
      action(observable, observer) if conditions(observable, observer)
    end

  end
end