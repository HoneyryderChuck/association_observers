# -*- encoding : utf-8 -*-
require "association_observers/version"
require "association_observers/notifiers/base"
require "association_observers/notifiers/propagation_notifier"

require "association_observers/ruby18" if RUBY_VERSION < "1.9"
require "active_support/core_ext/array/extract_options"
require "active_support/core_ext/string/inflections"


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
  autoload :Queue, "association_observers/queue"
  module Workers
    autoload :ManyDelayedNotification, "association_observers/workers/many_delayed_notification"
  end

  def self.orm_adapter
    raise "no adapter for your ORM"
  end

  def self.queue
    @queue ||= Queue.remote_queue
  end

  @options = {
      :batch_size => 50,
      :queue => {
        :engine => nil,
        :name => "observers",
        :drb_location => "druby://localhost:8787",
        :priority => nil
      }
  }

  def self.options
    @options
  end


  def self.included(model)
    model.extend ClassMethods
    model.send :include, InstanceMethods
  end

  # Methods to be added to observer associations
  module IsObserverMethods
    def self.included(base)
      base.extend(ClassMethods)
      AssociationObservers::orm_adapter.class_variable_set(base, :observable_options)
      if RUBY_VERSION < "1.9"
        base.observable_options = AssociationObservers::Backports.hash_select(AssociationObservers::options){|k, v| [:batch_size].include?(k) }
      else
        base.observable_options = AssociationObservers::options.select{|k, v| [:batch_size].include?(k) }
      end
    end

    module ClassMethods
      def observer? ; true ; end

      def batch_size=(val)
        raise "AssociationObservers: it must be an integer value" unless val.is_a?(Fixnum)
        self.observable_options[:batch_size] = val
      end

      private

      # @abstract
      # includes modules in the observer model
      def observer_extensions ; ; end


      # @param [Array] association_names collection  of association names
      # @return [Array] a collection of association class/options pairs
      def get_association_options_pairs(association_names)
        raise "should be defined in an adapter for the used ORM"
      end

      # @param [Array] associations collection of association names
      # @return [Array] the collection of associations which match collection associations
      def filter_collection_associations(associations)
        raise "should be defined in an adapter for the used ORM"
      end


      # given a collection of callbacks, it defines a private routine for each of them; this subroutine will notify the observers
      # which look on the callback the subroutine it is addressed to
      # @param [Array] callbacks a collection of callbacks as understood by the observers (:create, :update, :update, :destroy)
      # @param [Array] notifiers a collection of notifier classes
      # @return [Array] a collection of callback/sob-routine pairs
      def define_collection_callback_routines(callbacks, notifiers)
        raise "should be defined in an adapter for the used ORM"
      end

      # given a set of collection associations and a collection of callback/method_name pairs, it redefines the association
      # setting the respective callback routines for each of them
      # @param [Array] associations a collection of plural association names
      # @param [Hash, Array] callback_procs a collection of callback/method_name pairs
      def redefine_collection_associations_with_collection_callbacks(associations, callback_procs)
        raise "should be defined in an adapter for the used ORM"
      end
    end
  end

  # Methods to be added to observable associations
  module IsObservableMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def observable? ; true ; end

      private

      # @abstract
      # includes modules in the observable model
      def observable_extensions ; ; end

      # @abstract
      # loads the notifiers and observers for this observable class
      # @param [Array] notifiers notifiers to be included
      # @param [Array] callbacks collection of callbacks/methods to be observed
      # @param [Class] observer_class class of the observer
      # @param [Symbol] association_name name by which this observable is known in the observer
      def set_observers(notifiers, callbacks, observer_class, association_name)
        raise "should be defined in an adapter for the used ORM"
      end

      # @abstract
      # sets the triggering by callbacks of the notification
      # @param [Array] callbacks callbacks which will be observed and trigger notification behaviour
      def set_notification_on_callbacks(callbacks)
        raise "should be defined in an adapter for the used ORM"
      end
    end

    # blocks the observable behaviour
    def unobservable! ; @unobservable = true ; end
    # unblocks the observable behaviour
    def observable! ; @unobservable = false ; end

    private

    # informs the observers that something happened on this observable, passing all the observers to it
    # @param [Symbol] callback key of the callback being notified; only the observers for this callback will be run
    def notify! callback
      notify_observers([callback, []]) unless @unobservable
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


      # standard observer association methods
      include IsObserverMethods

      observer_extensions

      plural_associations = filter_collection_associations(args)

      association_name = (opts[:as] || self.name.demodulize.underscore).to_s
      notifier_classes = Array(opts[:notifiers] || opts[:notifier]).map{|notifier| notifier.to_s.end_with?("_notifier") ? notifier : "#{notifier}_notifier".to_s }
      observer_callbacks = Array(opts[:on] || [:save, :destroy])

      # no observer, how are you supposed to observe?
      AssociationObservers::orm_adapter.validate_parameters(self, args, notifier_classes, observer_callbacks)


      notifier_classes.map!{|notifier_class|notifier_class.to_s.classify.constantize} << PropagationNotifier

      # observer association methods per observer
      notifier_classes.each do |notifier_class|
        include "#{notifier_class.name}::ObserverMethods".constantize if notifier_class.constants.map(&:to_sym).include?(:ObserverMethods)
      end

      # 1: for each observed association, define behaviour
      get_association_options_pairs(args).each do |name, klass, options|
        klass.instance_eval do

          include IsObservableMethods

          observable_extensions

          attr_reader :unobservable

          # load observers from this observable association
          set_observers(notifier_classes, observer_callbacks, observer_class, (options[:as] || association_name).to_s, name)

          # sets the callbacks to inform observers
          set_notification_on_callbacks(observer_callbacks)
        end

      end

      # 2. for each collection association, insert after add and after remove callbacks

      # first step is defining the methods which will be called by the collection callbacks.
      # second step is redefining the associations with the proper callbacks to be triggered
      redefine_collection_associations_with_collection_callbacks(plural_associations, define_collection_callback_routines(observer_callbacks, notifier_classes))

    end
  end
end

if defined?(Rails::Railtie) # RAILS
  require 'association_observers/railtie'
else
  # ORM Adapters
  require 'association_observers/active_record' if defined?(ActiveRecord)
  require 'association_observers/data_mapper' if defined?(DataMapper)

end
