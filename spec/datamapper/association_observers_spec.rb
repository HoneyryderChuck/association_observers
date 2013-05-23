# -*- encoding : utf-8 -*-
require "helpers/datamapper_helper"
require "spec_helper"


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

  let(:observer1) {ObserverTest.create(:has_one_observable_test => HasOneObservableTest.new,
                                       :has_many_observable_tests => [HasManyObservableTest.new,
                                                                      HasManyObservableTest.new,
                                                                      HasManyObservableTest.new])}
  let(:observer2) { ObserverTest.create }
  let(:belongs_to_observable) {BelongsToObservableTest.create(:observer_test => observer1)}
  let(:collection_observable) {CollectionObservableTest.create(:observer_tests => [observer1, observer2])}
  describe "observer_methods" do
    let(:observer) {ObserverObserverTest.new}
    it "should be available" do
      observer.should be_observer
      observer.should_not be_observable
    end
  end

  describe "observable_methods" do
    let(:observable){BelongsToObservableTest.new}
    it "should be available" do
      observable.should_not be_observer
      observable.should be_observable
    end
  end

  describe "when the belongs to association gets banged" do
    before(:each) do
      belongs_to_observable.bang
    end
    it "should update its observer" do
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when the belongs to observable is updated" do
    before(:each) do
      belongs_to_observable.update(:name => "doof")
    end
    it "should update its observer" do
      belongs_to_observable.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  pending "when the belongs to observable is deleted" do
    before(:each) do
      observer1.belongs_to_observable_test.destroy
    end
    it "should destroy its observer" do
      observer1.reload.should be_deleted
    end
  end
  describe "when the observable hides itself" do
    before(:each) do
      observer1.update!(:updated => nil)
      belongs_to_observable.unobservable!
      belongs_to_observable.update(:name => "doof")
    end
    it "should not update its observer" do
      observer1.belongs_to_observable_test.name.should == "doof"
      observer1.reload.should_not be_updated
    end
  end
  describe "when the has one observable is updated" do
    before(:each) do
      observer1.has_one_observable_test.update(:name => "doof")
    end
    it "should update its observer" do
      observer1.has_one_observable_test.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when one of the has many observables is updated" do
    before(:each) do
      observer1.has_many_observable_tests.first.update(:name => "doof")
    end
    it "should update its observer" do
      observer1.has_many_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
    describe "and afterwards deleted" do
      before(:each) do
        observer1.update!(:deleted => false)
        observer1.has_many_observable_tests.first.destroy
      end
      it "should update its observer" do
        observer1.reload.should be_deleted
      end
    end
  end
  describe "when the has many through has been updated" do
    before(:each) do
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.create
      observer1.update!(:updated => false)
    end
    it "should update its observer" do
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.update(:name => "doof")
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when the collection observable is updated" do
    before(:each) do
      collection_observable.update(:name => "doof")
    end
    it "should update its observers" do
      collection_observable.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
      observer2.reload.should be_updated
      observer2.should_not be_deleted
    end
  end

  describe "when the observer has an observer itself" do
    let(:observer_observer) { ObserverObserverTest.create }
    before(:each) do
      observer1.update(:observer_observer_test => observer_observer)
    end
    describe "when the belongs to observable is updated" do
      before(:each) do
        belongs_to_observable.update(:name => "doof")
      end
      it "should update its observer and its observer's observer" do
        belongs_to_observable.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the has one observable is updated" do
      before(:each) do
        observer_observer.observer_test.has_one_observable_test.update(:name => "doof")
      end
      it "should update its observer and its observer's observer" do
        observer_observer.observer_test.has_one_observable_test.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when one of the has many observables is updated" do
      before(:each) do
        observer_observer.observer_test.has_many_observable_tests.first.update(:name => "doof")
      end
      it "should update its observer and its observer's observer" do
        observer_observer.observer_test.has_many_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the has many through has been updated" do
      before(:each) do
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.create
        observer1.update!(:updated => false)
        observer_observer.update!(:updated => false)
      end
      it "should update its observer" do
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.update(:name => "doof")
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the collection observable is updated" do
      before(:each) do
        collection_observable
        observer_observer.observer_test.reload.collection_observable_test.update(:name => "doof")
      end
      it "should update its observers and its observer's observer" do
        observer_observer.observer_test.collection_observable_test.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
  end

  describe "when the observer has an observer collection itself" do
    before(:each) do
      ManyObserverObserverTest.create(:observer_test => observer1)
      observer1.reload
    end
    describe "and the batch size for the observer observers has changed" do
      before do
        @old_batch_size = ObserverTest.observable_options[:batch_size]
        ManyObserverObserverTest.stub! :observable? => true
        ManyObserverObserverTest.any_instance.stub :notify_observers => true
        ObserverTest.batch_size = 101
      end
      after do
        ObserverTest.batch_size = @old_batch_size
      end
      it "should update the observer observers collection with the right batch size" do
        AssociationObservers.should_receive(:batched_each).with(anything, 101).any_number_of_times
        belongs_to_observable.update(:name => "doof")
      end
    end
  end

  describe "when the association is a joined through" do
    class HasOneThroughObservableTest
      include DataMapper::Resource
      property :id, Serial
      property :name, String

      belongs_to :has_one_observable_test, :required => false
      has 1, :observer_test, :through => :has_one_observable_test
    end

    class HasOneObservableTest
      has 1, :has_one_through_observable_test
    end

    class ObserverTest

      has 1, :has_one_through_observable_test, :through => :has_one_observable_test
      observes :has_one_through_observable_test, :notifiers => :test_update, :on => :update
    end

    DataMapper.auto_upgrade!

    let(:through_observable) { HasOneThroughObservableTest.create(:has_one_observable_test => HasOneObservableTest.new(:observer_test => ObserverTest.new)) }
    let(:observer) {through_observable.has_one_observable_test.observer_test}
    describe "when the has one association is updated" do
      before(:each) do
        observer.update(:updated => nil)
        through_observable.update(:name => "doof")
      end
      it "should update its observer" do
        through_observable.name.should == "doof"
        observer.reload.should be_updated
      end
    end

  end

  # TODO: should this be responsibility of the associations or from the observers? check further into this
  pending "when an observable also observes its observer" do

    class ObservableAbstractTest
      property :successful, Boolean
    end

    DataMapper.auto_upgrade!

    before(:all) do
      class HasOneObservableTest
        observes :observer_test, :notifiers => :test_update, :on => :update
      end
    end
    describe "when something changes on the observable" do
      before(:each) do
        observer1.has_one_observable_test.update(:name => "doof")
      end
      it "should update only the observer (and therefore avoid infinite cycle)" do
        observer1.has_one_observable_test.name.should == "doof"
        observer1.reload.should be_updated
      end
    end
  end

end