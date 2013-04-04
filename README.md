# AssociationObservers

This is an alternative implementation of the observer pattern. As you may know, Ruby (and Rails/ActiveRecord, and DataMapper) already have an
implementation of it. This implementation is a variation of the pattern, so it is not supposed to supersede the existing
implementations, but "complete" them for the specific use-cases addressed.

[![Build Status](https://travis-ci.org/TiagoCardoso1983/association_observers.png?branch=master)](https://travis-ci.org/TiagoCardoso1983/association_observers)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/TiagoCardoso1983/association_observers)

## Comparison with the Observer Pattern

The Observer Pattern clearly defines two roles: the observer and the observed. The observer registers itself by the
observed. The observed decides when (for which "actions") to notify the observer. The observer knows what to do when notified.

What's the limitation? The observed has to know when and whom to notify. The observer has to know what to do. For this
logic to be implemented for two other separate entities, behaviour has to be copied from one place to the other. So, why
not delegate this information (to whom, when, behaviour) to a third role, the notifier?

## Comparison with Ruby Observable library

Great library, which works great for POROs, but not for models (specifically ActiveRecord, which overwrites a lot of its
functionality)

## Comparison with ActiveRecord Observers

Observers there are external entities which observe models. They don't exactly work as links between two models, just
extract functionality (callbacks) which would otherwise flood the model. For that, they're great. For the rest, not really.

## Comparison with DataMapper Observers

Currently doesn't support callbacks on collections (even though it supports observation for any method, cool!)

### Installation

Add this line to your application's Gemfile:

    gem 'association_observers'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install association_observers

### Usage

Here is a functional example:

       require 'logger'

       LOGGER = Logger.new(STDOUT)

       # Notifiers
       class HaveSliceNotifier < Notifier::Base

         def action(cake, kid)
           cake.update_column(:slices, cake.slices - 1)
           cake.destroy if cake.slices == 0
           kid.increment(:slices).save
         end

       end

       class BustKidsAssNotifier < Notifier::Base

         module ObserverMethods
           def bust_kids_ass!
             LOGGER.info("Slam!!")
           end
         end

         module ObservableMethods
           def is_for_grandpa?
             true # it is always for grandpa
           end
         end

         def conditions(cake, mom)
           cake.is_for_grandpa?
         end

         def action(cake, mom)
           mom.bust_kids_ass!
         end

       end

       class TellKidHesFatNotifier < Notifier::Base

         module ObservableMethods

           def cry!
             LOGGER.info(":'(")
           end

           def throw_slices_away!
             update_column(:slices, 0)
           end
         end

         def conditions(kid, mom)
           kid.slices > 20
         end

         def action(kid, mom)
           LOGGER.info("Hey Fatty, BEEFCAKE!!!!!")
           kid.cry!
           kid.throw_slices_away!
         end

       end


       # TABLES

       ActiveRecord::Schema.define do
         create_table :cakes, :force => true do |t|
           t.integer :slices
           t.integer :mom_id
         end
         create_table :kids, :force => true do |t|
           t.integer :mom_id
           t.integer :slices, :default => 0
         end
         create_table :moms, :force => true do |t|
         end
       end

       # ENTITIES

       class Cake < ActiveRecord::Base

         def self.default_slices ; 8 ; end
         belongs_to :mom
         has_one :kid, :through => :mom
         before_create do |record|
           record.slices ||= record.class.default_slices
         end
       end

       class Mom < ActiveRecord::Base
         has_one :kid
         has_many :cakes
       end

       class Kid < ActiveRecord::Base
         belongs_to :mom
         has_many :cakes, :through => :mom

         observes :cakes, :notifier => :have_slice, :on => :create
       end

       class Mom < ActiveRecord::Base
         observes :cakes, :on => :destroy, :notifier => :bust_kids_ass
         observes :kid, :on => :update, :notifier => :tell_kid_hes_fat
       end

You can find this under the examples.

The #observes method for the models accepts as argument the association being observed and a set of options:

* as : if the association is polymorphic, then this parameter has to be filled with the name by which the observer is recognized by the observed
* on : accepts one event or a set of events to observe (:create, :update, :save, :destroy) for the observed association (default: :save)
* notifier(s?): accepts one notifier or a set of notifiers that will handle the events; notifier name has to match the name of the notifier being defined by yourself;
  if you don't set any notifier, then the events on the observed will only propagate to the observers of the observer (if it is being observed)


The other important task is to define your own notifiers. First, where. For Rails, the gem expects a "notifiers" folder to exist under the "app" folder.
Everywhere else, it's entirely up to you where you should define them.
Second, how. Your notifier must inherit from Notifier::Base. This class provides you with hook methods you should/could redefine your way:

Methods to overwrite:
* action(observable, observer) : where you should define the behaviour which results of the observation of an event
* conditions(observable, observer) : checks whether the action should be run (defaults to true if not overwritten)

Additionally, you can optimize the behaviour for collection associations. Let's say a brand has many products which know
its owner, and when the brand changes from owner, you want to update a certain flag on products. Per default, the action
 will be run individually for every product. If we are talking about DB statements and 100 products, it will be 100 sequential
 statements... That's a drag if you can accomplish that in one DB statement. for that, you can overwrite these two methods:

 * notify_many(observable, observers)
 * conditions_many(observable, observers)

 the observers parameters is a container of not-yet loaded collection associations. Check your ORM's documentation to know what you can
 do with it and whether you can achieve your result without populating it (there is such a use under the examples).

Purpose of the Notifier is to abstract the behaviour from the Observer relationship between associations. But if you still
need to complement/overwrite behaviour from your observer/observable models, you can write it in notifier-specific modules,
the ObserverMethods and the ObservableMethods, which will be included in the respective models.

### Background Queues

This gem supports the 3 most popular background queue implementations around: Delayed Job, Resque and Sidekiq. If you are
using this gem out of Rails, you can do:

       AssociationObservers::options[:queue][:engine] = :delayed_job # or :sidekiq, or :resque

if in Rails, you can do it in application.rb:

       module YourApp
         class Application < Rails::Application
           ...
           config.association_observers.queue.engine = :delayed_job # or :sidekiq, or :resque
           ...
         end
       end

and that's it. Why is this important? The notification of observer collections, when you don't rewrite the
#notify_many hook method of the notifier, takes the following approach:

* Queries the collection in batches (of 50, by default)
* Iterates over each batch
* Performs the #update hook method on each

It also takes this approach to the propagation. Batch-querying is much better than querying all at once, but you still
load everything and perform the various iterations synchronously. If you already use one of the aforementioned background
queues, each batch will generate a job which will be handled asynchronously. You also have the control over the batch size.
If you want to set a new default batch size, just:

       # standard
       AssociationObservers::options[:batch_size] = 200 # or 20...

       # rails way
       module YourApp
         class Application < Rails::Application
           ...
           config.association_observers.batch_size = 200 # or 20...
           ...
         end
       end

You can also set the queue name (default: "observers" and priority (if using delayed job) on the options, they are just another option under queue.

### TODOs

* Support for other ORM's (currently supporting ActiveRecord and DataMapper)
* Action routine definition on the "#observes" declaration (sometimes one does not need the overhead of writing a notifier)
* Overall spec readability

* ActiveRecord: Observe method calls (currently only observing model callbacks)
* DataMapper: Support Many-to-Many collection observation (currently ignoring)

## STATUS

* Support for ActiveRecord
* Support for DataMapper

* Integration with delayed job, resque and sidekiq

### Rails

The observer models have to be eager-loaded for the observer/observable behaviour to be extended in the respective associations.
It is kind of a drag, but a drag the Rails Observers already suffer from (these have to be declared in the application configuration).

### Non-Rails

If you are auto-loading your models, the same logic from the paragraph above applies. If you are requiring your models,
 just proceed, this is not your concern :)

### Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
