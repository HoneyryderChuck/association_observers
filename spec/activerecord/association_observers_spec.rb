# -*- encoding : utf-8 -*-
require "helpers/active_record_helper"
require "spec_helper"
require "observer_example_spec"


describe AssociationObservers do
  class TestUpdateNotifier < Notifier::Base

    def action(observable, observer)
      observer.update_attributes(:updated => true)
    end

    def notify_many(observable, many_observers)
      many_observers.each do |observers|
        observers.update_all(:updated => true)
      end
    end

  end
  
  class TestDestroyNotifier < Notifier::Base

    def action(observable, observer)
      observer.update_attributes(:deleted => true)
    end

    def notify_many(observable, many_observers)
      many_observers.each do |observers|
        observers.each do |observer|
          observer.update_all(:deleted => true)
        end
      end
    end

  end
  

  class ObservableAbstractTest < ActiveRecord::Base
    self.table_name ='association_observable_tests'
    attr_accessible :name
  end

  class BelongsToObservableTest < ObservableAbstractTest
    attr_accessible :observer_test
    has_one :observer_test
  end
  class CollectionObservableTest < ObservableAbstractTest
    attr_accessible :observer_tests
    has_many :observer_tests
  end
  class HasOneObservableTest < ObservableAbstractTest
    attr_accessible :observer_test,
                    :has_one_through_observable_test
    belongs_to :observer_test
    has_one :has_one_through_observable_test
  end
  class HasManyObservableTest < ObservableAbstractTest
    attr_accessible :observer_test, :has_many_through_observable_tests
    belongs_to :observer_test
    has_many :has_many_through_observable_tests
  end
  class HasManyThroughObservableTest < ObservableAbstractTest
    attr_accessible :observer_test, :has_many_observable_test
    belongs_to :has_many_observable_test
    has_one :observer_test, :through => :has_many_observable_test
  end

  class PolymorphicHasManyObservableTest < ObservableAbstractTest
    attr_accessible :observer
    belongs_to :observer, :polymorphic => true
  end
  class HasOnePolymorphicObservableTest < ObservableAbstractTest
    self.table_name ='association_polymorphic_observable_tests'
    belongs_to :observer, :polymorphic => true
    attr_accessible :observer
  end
  class HabtmObservableTest < ObservableAbstractTest
    attr_accessible :observer_tests
    has_and_belongs_to_many :observer_tests
  end
  class HasOneThroughObservableTest < ObservableAbstractTest
    self.table_name ='association_polymorphic_observable_tests'
    belongs_to :has_one_observable_test
    has_one :observer_test, :through => :has_one_observable_test
    attr_accessible :has_one_observable_test
  end


  class ObserverAbstractTest < ActiveRecord::Base
    self.table_name = 'association_observer_tests'
    attr_accessible :updated, :deleted
  end

  class OtherPossibleObserverTest < ActiveRecord::Base # Why Active::Record? The association klass is the base class
    self.table_name = 'association_observer_tests'
    attr_accessible :updated, :deleted
    has_one :has_one_polymorphic_observable_test, :as => :observer
    attr_accessible :has_one_polymorphic_observable_test
    # does not define observables, therefore should not observe
  end



  class ObserverTest < ObserverAbstractTest

    belongs_to :belongs_to_observable_test
    belongs_to :collection_observable_test
    has_one :has_one_observable_test
    has_many :has_many_observable_tests
    has_one :has_one_polymorphic_observable_test, :as => :observer
    has_one :has_one_through_observable_test, :through => :has_one_observable_test

    has_many :has_many_through_observable_tests, :through => :has_many_observable_tests

    has_many :polymorphic_has_many_observable_tests, :as => :observer

    has_one :observer_observer_test
    has_many :many_observer_observer_tests

    has_and_belongs_to_many :habtm_observable_tests

    attr_accessible :belongs_to_observable_test,
                    :has_one_observable_test,
                    :has_many_observable_tests,
                    :has_many_through_observable_tests,
                    :polymorphic_has_many_observable_tests,
                    :collection_observable_test,
                    :observer_observer_test,
                    :habtm_observable_tests,
                    :has_one_polymorphic_observable_test,
                    :has_one_through_observable_test

    observes :habtm_observable_tests, :notifiers => :test_update, :on => :create
    observes :belongs_to_observable_test,
             :has_one_observable_test,
             :collection_observable_test,
             :has_many_through_observable_tests,
             :polymorphic_has_many_observable_tests,
             :has_many_observable_tests,
             :habtm_observable_tests, :notifiers => :test_update, :on => :update
    observes :belongs_to_observable_test,
             :has_one_observable_test,
             :collection_observable_test,
             :has_many_through_observable_tests,
             :has_many_observable_tests,
             :polymorphic_has_many_observable_tests,
             :habtm_observable_tests, :notifiers => :test_destroy, :on => :destroy

    observes :has_one_polymorphic_observable_test, :as => :observer, :notifiers => :test_update, :on => :update
    observes :has_one_through_observable_test, :notifiers => :test_update, :on => :update
  end

  class ObserverObserverTest < ObserverAbstractTest
    belongs_to :observer_test
    attr_accessible :observer_test

    observes :observer_test, :notifiers => :test_update, :on => :update
  end

  class ManyObserverObserverTest < ObserverAbstractTest
    belongs_to :observer_test
    attr_accessible :observer_test

    observes :observer_test, :notifiers => :test_update, :on => :update
  end

  ActiveRecord::Schema.define do
    create_table :association_observer_tests, :force => true do |t|
      t.column :type, :string # for polymorphic test only
      t.column :observer_test_id, :integer
      t.column :belongs_to_observable_test_id, :integer
      t.column :collection_observable_test_id, :integer
      t.column :updated, :boolean
      t.column :deleted, :boolean
    end
    create_table :association_observable_tests, :force => true do |t|
      t.column :observer_test_id, :integer
      t.column :observer_type, :string # for polymorphic test only
      t.column :observer_id, :integer # for polymorphic test only
      t.column :has_many_observable_test_id, :integer
      t.column :name, :string
    end
    create_table :habtm_observable_tests_observer_tests, :id => false, :force => true do |t|
      t.column :habtm_observable_test_id, :integer
      t.column :observer_test_id, :integer
    end

    create_table :association_polymorphic_observable_tests, :force => true do |t|
      t.column :observer_id, :integer
      t.column :observer_type, :string
      t.column :has_one_observable_test_id, :integer
      t.column :name, :string
    end

  end

  def build_model(klass, attributes={})
    klass.new(attributes)
  end

  def create_model(klass, attributes={})
    klass.create(attributes)
  end

  def update_model(model, attributes={})
    model.update_attributes(attributes)
  end



  it_should_behave_like "example using observers"


end