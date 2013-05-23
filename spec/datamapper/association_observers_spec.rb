# -*- encoding : utf-8 -*-
require "helpers/datamapper_helper"
require "spec_helper"
require "observer_example_spec"


describe AssociationObservers do
  class TestUpdateNotifier < Notifier::Base

    def action(observable, observer)
      if observer.dirty?
        observer.updated = true
      else
        observer.update!(:updated => true)
      end
    end

    def notify_many(observable, many_observers)
      many_observers.each do |observers|
        observers.update!(:updated => true)
      end
    end

  end
  
  class TestDestroyNotifier < Notifier::Base

    def action(observable, observer)
      observer.update(:deleted => true)
    end

    def notify_many(observable, many_observers)
      many_observers.each do |observers|
        observers.each do |observer|
          observer.update!(:deleted => true)
        end
      end
    end

  end
  

  class BelongsToObservableTest 
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    has 1, :observer_test

    def bang
      "Bang"
    end

  end
  class CollectionObservableTest 
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    has n, :observer_tests
  end
  class HasOneObservableTest 
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    belongs_to :observer_test, :required => false
    has 1, :has_one_through_observable_test
  end
  class HasManyObservableTest 
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    belongs_to :observer_test, :required => false
    has n, :has_many_through_observable_tests
  end
  class HasManyThroughObservableTest 
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    belongs_to :has_many_observable_test, :required => false
    has 1, :observer_test, :through => :has_many_observable_test
  end

  class HabtmObservableTest
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    has n, :observer_tests, :through => Resource
  end
  class HasOneThroughObservableTest
    include DataMapper::Resource
    property :id, Serial
    property :name, String

    belongs_to :has_one_observable_test, :required => false
    has 1, :observer_test, :through => :has_one_observable_test
  end



  class ObserverTest
    include DataMapper::Resource

    property :id, Serial
    property :type, Discriminator
    property :updated, Boolean
    property :deleted, Boolean

    belongs_to :belongs_to_observable_test, :required => false
    belongs_to :collection_observable_test, :required => false
    has 1, :has_one_observable_test
    has n, :has_many_observable_tests

    has n, :has_many_through_observable_tests, :through => :has_many_observable_tests, :via => :target, :required => false


    has 1, :observer_observer_test
    has n, :many_observer_observer_tests

    has n, :habtm_observable_tests, :through => Resource

    has 1, :has_one_through_observable_test, :through => :has_one_observable_test


    observes :habtm_observable_tests, :notifiers => :test_update, :on => :create
    observes :belongs_to_observable_test,
             :has_one_observable_test,
             :collection_observable_test,
             :has_many_through_observable_tests,
             :has_many_observable_tests,
             :habtm_observable_tests, :notifiers => :test_update, :on => :update
    observes :belongs_to_observable_test,
             :has_one_observable_test,
             :collection_observable_test,
             :has_many_through_observable_tests,
             :has_many_observable_tests,
             :habtm_observable_tests, :notifiers => :test_destroy, :on => :destroy
    observes :belongs_to_observable_test, :notifiers => :test_update, :on => :bang
    observes :has_one_through_observable_test, :notifiers => :test_update, :on => :update
  end

  class ObserverObserverTest
    include DataMapper::Resource

    property :id, Serial
    property :type, Discriminator
    property :updated, Boolean
    property :deleted, Boolean

    belongs_to :observer_test, :required => false

    observes :observer_test, :notifiers => :test_update, :on => :update
  end

  class ManyObserverObserverTest
    include DataMapper::Resource

    property :id, Serial
    property :type, Discriminator
    property :updated, Boolean
    property :deleted, Boolean

    belongs_to :observer_test, :required => false

    observes :observer_test, :notifiers => :test_update, :on => :update
  end






  DataMapper.finalize

  DataMapper.auto_migrate!


  # aux metods
  def build_model(klass, attributes={})
    klass.new(attributes)
  end

  def create_model(klass, attributes={})
    klass.create(attributes)
  end

  def update_model(model, attributes={})
    model.update(attributes)
  end

  def destroy_model(model)
    model.destroy
  end

  def update_model!(model, attributes={})
    model.update!(attributes)
  end




  it_should_behave_like "example using observers" do
    describe "when the belongs to association gets banged" do
      before(:each) do
        belongs_to_observable.bang
      end
      it "should update its observer" do
        observer1.reload.should be_updated
        observer1.should_not be_deleted
      end
    end
  end


  describe "specific datamapper observers" do
    let(:observer1) {create_model(ObserverTest) }
    let(:belongs_to_observable) { create_model(BelongsToObservableTest, :observer_test => observer1)}

  end


end