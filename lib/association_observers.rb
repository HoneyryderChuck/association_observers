# -*- encoding : utf-8 -*-
require "association_observers/version"
require "association_observers/notifiers/base"
require "association_observers/notifiers/propagation_notifier"

require "association_observers/ruby18" if RUBY_VERSION < "1.9"

# Here it is defined the basic behaviour of how observer/observable model associations are set. There are here three
# main roles defined: The observer associations, the observable associations, and the notifiers (the real observers).
# Observer Associations: those are the associations of an observable which will be "listening/observing" to updates
#
# Observable Associations: those are the associations of an observer which will trigger "listening/observing" events on these
#
# Notifiers: These are the handlers which will implement the behaviour desired, knowing who observes and who is observed
#
# Purpose of these role definitions is to separate the listening/observing behaviour from the implementation of the logic
# associated to it. Examples of these: model A has many Bs. The Bs from A are so many that you'd like to want to store
# a count of the Bs on A. For that you would like A to be informed each time a B is added/deleted, so you could update
# the counter accordingly. So in this case, A observes B, and B is observed by A. But The CounterNotifier, which is an
# entity independent from A and B, will implement the logic of updating the counter from Bs on A. This way we can achieve
# multiple behaviour implementation.
#
# @author Tiago Cardoso
module AssociationObservers
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

  # Methods to be added to observer associations
  module IsObserverMethods
    def self.included(base) ; base.extend(ClassMethods) ; end

    module ClassMethods
      def observer? ; true ; end
    end
  end

  # Methods to be added to observable associations
  module IsObservableMethods
    def self.included(base) ; base.extend(ClassMethods) ; end

    module ClassMethods
      def observable? ; true ; end

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

    def unobservable! ; @unobservable = true ; end
    def observable! ; @unobservable = false ; end

    private

    # informs the observers that something happened on this observable, passing all the observers to it
    # @param [Symbol] callback key of the callback being notified; only the observers for this callback will be run
    def notify! callback
      notify_observers(callback) unless @unobservable
    end
  end

  module InstanceMethods
    def observer? ; self.class.observer? ; end
    def observable? ; self.class.observable? ; end
  end

  module ClassMethods
    def observer? ; false ; end
    def observable? ; false ; end

    # DSL method which triggers all the behaviour. It sets self as an observer association from defined observable
    # associations in it (these have to be defined in the model).
    #
    # @param [Symbol [, Symbol...]] args the self associations which will be observed
    # @param [Hash] opts additional options
    # @option opts [Symbol] :as name of the polymorphic association on the observables if it is defined like that
    # @option opts [Symbol, Array] :observers name of the observers to be applied (in underscore notation: EmailNotifier would be :email_notifier)
    # @option opts [Symbol, Array] :on which callbacks should the observers be aware of (options are :create, :save and :destroy; callback triggered will always be an after_)
    def observes(*args)
      opts = args.extract_options!
      observer_class = self

      plural_associations = args.select{ |arg| self.reflections[arg].collection? }

      association_name = (opts[:as] || self.name.demodulize.underscore).to_s
      notifier_classes = Array(opts[:notifiers] || opts[:notifier]).map{|notifier| notifier.to_s.end_with?("_notifier") ? notifier : "#{notifier}_notifier".to_s }
      observer_callbacks = Array(opts[:on] || [:save, :destroy])

      # no observer, how are you supposed to observe?
      raise "Invalid callback; possible options: :create, :update, :save, :destroy" unless observer_callbacks.all?{|o|[:create,:update,:save,:destroy].include?(o.to_sym)}

      # standard observer association methods
      include IsObserverMethods

      notifier_classes.map!{|notifier_class|notifier_class.to_s.classify.constantize} << PropagationNotifier

      # observer association methods per observer
      notifier_classes.each do |notifier_class|
        include "#{notifier_class.name}::ObserverMethods".constantize if notifier_class.constants.map(&:to_sym).include?(:ObserverMethods)
      end

      # 1: for each observed association, define behaviour
      self.reflect_on_all_associations.select{ |r| args.include?(r.name) }.map{|r| [r.klass, r.options] }.each do |klass, options|
        klass.instance_eval do

          include ActiveModel::Observing
          include IsObservableMethods
          attr_reader :unobservable

          # load observers from this observable association
          set_observers(notifier_classes, observer_callbacks, observer_class, (options[:as] || association_name).to_s)

          # sets the callbacks to inform observers
          set_notification_on_callbacks(observer_callbacks)
        end

      end

      # 2. for each collection association, insert after add and after remove callbacks

      # first step is defining the methods which will be called by the collection callbacks.
      # second step is redefining the associations with the proper callbacks to be triggered
      __redefine_collection_associations_with_collection_callbacks__(plural_associations, __define_collection_callback_routines__(observer_callbacks, notifier_classes))

    end

    # given a collection of callbacks, it defines a private routine for each of them; this subroutine will notify the observers
    # which look on the callback the subroutine it is addressed to
    # @param [Array] callbacks a collection of callbacks as understood by the observers (:create, :update, :update, :destroy)
    # @param [Array] notifiers a collection of notifier classes
    # @return [Array] a collection of callback/sob-routine pairs
    def __define_collection_callback_routines__(callbacks, notifiers)
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

    # given a set of collection associations and a collection of callback/method_name pairs, it redefines the association
    # setting the respective callback routines for each of them
    # @param [Array] associations a collection of plural association names
    # @param [Hash, Array] callback_procs a collection of callback/method_name pairs
    def __redefine_collection_associations_with_collection_callbacks__(associations, callback_procs)
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
          assoc_options = AssociationObservers::extended_to_s(a.options)
          callback_options = AssociationObservers::extended_to_s(callbacks)
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

if defined?(Rails::Railtie) # RAILS
  require 'association_observers/railtie'
else
  require 'association_observers/activerecord'
end
