# -*- encoding : utf-8 -*-
require "./spec/helpers/active_record_helper"
require "./spec/spec_helper"


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
    attr_accessible :observer_test
    belongs_to :observer_test
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
  class HabtmObservableTest < ObservableAbstractTest
    attr_accessible :observer_tests
    has_and_belongs_to_many :observer_tests
  end


  class ObserverAbstractTest < ActiveRecord::Base
    self.table_name = 'association_observer_tests'
    attr_accessible :updated, :deleted
  end

  class ObserverTest < ObserverAbstractTest

    belongs_to :belongs_to_observable_test
    belongs_to :collection_observable_test
    has_one :has_one_observable_test
    has_many :has_many_observable_tests

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
                    :habtm_observable_tests

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
  end

  let(:observer1) {ObserverTest.create(:has_one_observable_test => HasOneObservableTest.new,
                                       :has_many_observable_tests => [HasManyObservableTest.new,
                                                                      HasManyObservableTest.new,
                                                                      HasManyObservableTest.new])}
  let(:observer2) { ObserverTest.create }
  let(:belongs_to_observable) {BelongsToObservableTest.new(:observer_test => observer1)}
  let(:collection_observable) {CollectionObservableTest.create(:observer_tests => [observer1, observer2])}
  let(:polymorphic_observable) {PolymorphicHasManyObservableTest.create(:observer => observer2)}
  before do
    observer1.belongs_to_observable_test = belongs_to_observable
    observer1.save
  end
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

  describe "when the belongs to observable is updated" do
    before(:each) do
      belongs_to_observable.update_attributes(:name => "doof")
    end
    it "should update its observer" do
      belongs_to_observable.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when the belongs to observable is deleted" do
    before(:each) do
      observer1.belongs_to_observable_test.destroy
    end
    it "should destroy its observer" do
      observer1.reload.should be_deleted
    end
  end
  describe "when the observable hides itself" do
    before(:each) do
      observer1.update_column(:updated, nil)
      belongs_to_observable.unobservable!
      belongs_to_observable.update_attributes(:name => "doof")
    end
    it "should not update its observer" do
      observer1.belongs_to_observable_test.name.should == "doof"
      observer1.reload.should_not be_updated
    end
  end
  describe "when the has one observable is updated" do
    before(:each) do
      observer1.has_one_observable_test.update_attributes(:name => "doof")
    end
    it "should update its observer" do
      observer1.has_one_observable_test.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when one of the has many observables is updated" do
    before(:each) do
      observer1.has_many_observable_tests.first.update_attributes(:name => "doof")
    end
    it "should update its observer" do
      observer1.has_many_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
    describe "and afterwards deleted" do
      before(:each) do
        observer1.update_column(:deleted, false)
        observer1.has_many_observable_tests.first.destroy
      end
      it "should update its observer" do
        observer1.reload.should be_deleted
      end
    end
  end
  describe "when one of the polymorphic has many is updated" do
    before(:each) do
      observer1.polymorphic_has_many_observable_tests = [PolymorphicHasManyObservableTest.new,
                                                         PolymorphicHasManyObservableTest.new,
                                                         PolymorphicHasManyObservableTest.new]
      observer1.update_column(:updated, false)
      observer1.reload
    end
    it "should update its observer" do
      observer1.polymorphic_has_many_observable_tests.first.update_attributes(:name => "doof")
      observer1.polymorphic_has_many_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
    describe "having another polymorphic observable of same type somewhere else" do
      before(:each) do
        observer2.update_column(:updated, false)
      end
      it "should not update its observer" do
        observer1.polymorphic_has_many_observable_tests.first.update_attributes(:name => "doof")
        observer1.polymorphic_has_many_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer1.should_not be_deleted
        observer2.reload.should_not be_updated
        observer2.should_not be_deleted
      end
    end
  end
  describe "when the has many through has been updated" do
    before(:each) do
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.create
      observer1.update_column(:updated, false)
    end
    it "should update its observer" do
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.update_attributes(:name => "doof")
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when an has and belongs to many association" do
    describe "has been created" do
      before(:each) do
        observer1.update_column(:updated, false)
        observer1.habtm_observable_tests.create(:name => "doof")
      end
      it "should update its observer" do
        observer1.habtm_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer1.should_not be_deleted
      end
      describe "and then updated" do
        before(:each) do
          observer1.update_column(:updated, false)
          observer1.habtm_observable_tests.first.update_attributes(:name => "superdoof")
        end
        it "should update its observer" do
          observer1.habtm_observable_tests.first.name.should == "superdoof"
          observer1.reload.should be_updated
          observer1.should_not be_deleted
        end
      end
      describe "and afterwards deleted" do
        before(:each) do
          observer1.update_column(:deleted, false)
          observer1.habtm_observable_tests.delete(observer1.habtm_observable_tests.first)
        end
        it "should update its observer" do
          observer1.reload.should be_deleted
        end
      end
      describe "and completely replaced" do
        before(:each) do
          observer1.update_column(:updated, false)
          observer1.update_column(:deleted, false)
          observer1.habtm_observable_tests = [HabtmObservableTest.new]
        end
        it "should update and delete the observer" do
          observer1.reload.should be_updated
          observer1.reload.should be_deleted
        end
      end

    end
    describe "has been linked from an existing assoc" do
      before(:each) do
        t = HabtmObservableTest.create(:name => "doof")
        observer1.habtm_observable_tests << t
        observer1.update_column(:updated, false)
        observer1.habtm_observable_tests.first.update_attributes(:name => "superdoof")
      end
      it "should update its observer" do
        observer1.habtm_observable_tests.first.name.should == "superdoof"
        observer1.reload.should be_updated
        observer1.should_not be_deleted
      end
      describe "and afterwards deleted" do
        before(:each) do
          observer1.update_column(:deleted, false)
          observer1.habtm_observable_tests.delete(observer1.habtm_observable_tests.first)
        end
        it "should update its observer" do
          observer1.reload.should be_deleted
        end
      end

    end
  end
  describe "when the collection observable is updated" do
    before(:each) do
      collection_observable.update_attributes(:name => "doof")
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
      observer1.update_attribute(:observer_observer_test, observer_observer)
    end
    describe "when the belongs to observable is updated" do
      before(:each) do
        belongs_to_observable.update_attributes(:name => "doof")
      end
      it "should update its observer and its observer's observer" do
        belongs_to_observable.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the has one observable is updated" do
      before(:each) do
        observer_observer.observer_test.has_one_observable_test.update_attributes(:name => "doof")
      end
      it "should update its observer and its observer's observer" do
        observer_observer.observer_test.has_one_observable_test.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when one of the has many observables is updated" do
      before(:each) do
        observer_observer.observer_test.has_many_observable_tests.first.update_attributes(:name => "doof")
      end
      it "should update its observer and its observer's observer" do
        observer_observer.observer_test.has_many_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when one of the polymorphic has many is updated" do
      before(:each) do
        observer1.polymorphic_has_many_observable_tests = [PolymorphicHasManyObservableTest.new,
                                                           PolymorphicHasManyObservableTest.new,
                                                           PolymorphicHasManyObservableTest.new]
        observer1.update_column(:updated, false)
        observer_observer.update_column(:updated, false)
      end
      it "should update its observer" do
        observer_observer.observer_test.polymorphic_has_many_observable_tests.first.update_attributes(:name => "doof")
        observer_observer.observer_test.polymorphic_has_many_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the has many through has been updated" do
      before(:each) do
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.create
        observer1.update_column(:updated, false)
        observer_observer.update_column(:updated, false)
      end
      it "should update its observer" do
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.update_attributes(:name => "doof")
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the collection observable is updated" do
      before(:each) do
        collection_observable
        observer_observer.observer_test.reload.collection_observable_test.update_attributes(:name => "doof")
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
      observer1.update_attribute(:many_observer_observer_tests, [ManyObserverObserverTest.new,
                                                                 ManyObserverObserverTest.new,
                                                                 ManyObserverObserverTest.new])
      observer1.reload
    end
    describe "and the batch size for the observer observers has changed" do
      before do
        @old_batch_size = ObserverTest.observable_options[:batch_size]
        ManyObserverObserverTest.stub! :observable? => true
        ObserverTest.batch_size = 101
      end
      after do
        ObserverTest.batch_size = @old_batch_size
      end
      it "should update the observer observers collection with the right batch size" do
        AssociationObservers.should_receive(:batched_each).with(anything, 101).any_number_of_times
        belongs_to_observable.update_attributes(:name => "doof")
      end
    end
  end


  describe "when the association is polymorphic" do
    class HasOnePolymorphicObservableTest < ObservableAbstractTest
      self.table_name ='association_polymorphic_observable_tests'
      belongs_to :observer, :polymorphic => true
      attr_accessible :observer
    end

    class ObserverTest < ObserverAbstractTest
      has_one :has_one_polymorphic_observable_test, :as => :observer
      attr_accessible :has_one_polymorphic_observable_test
      observes :has_one_polymorphic_observable_test, :as => :observer, :notifiers => :test_update, :on => :update
    end

    class OtherPossibleObserverTest < ActiveRecord::Base # Why Active::Record? The association klass is the base class
      self.table_name = 'association_observer_tests'
      attr_accessible :updated, :deleted
      has_one :has_one_polymorphic_observable_test, :as => :observer
      attr_accessible :has_one_polymorphic_observable_test
      # does not define observables, therefore should not observe
    end

    ActiveRecord::Schema.define do
      create_table :association_polymorphic_observable_tests, :force => true do |t|
        t.column :observer_id, :integer
        t.column :observer_type, :string
        t.column :name, :string
      end
    end
    let(:polymorphic_observable) { HasOnePolymorphicObservableTest.create(:observer => ObserverTest.new) }
    let(:observer) {polymorphic_observable.observer}
    before(:each) do
      observer.update_column(:updated, nil)
    end
    describe "when the has one association is updated" do
      before(:each) do
        polymorphic_observable.update_attributes(:name => "doof")
      end
      it "should update its observer" do
        polymorphic_observable.name.should == "doof"
        observer.reload.should be_updated
      end
    end
    describe "when the observable is not observed" do
      let(:other_polymorphic_observable) { HasOnePolymorphicObservableTest.create(:observer => OtherPossibleObserverTest.new) }
      let(:non_observer){ other_polymorphic_observable.observer }
      describe " and the observable is updated" do
        before(:each) do
          other_polymorphic_observable.update_attributes(:name => "doof")
        end
        it "should not update its (non) observer" do
          other_polymorphic_observable.name.should == "doof"
          non_observer.reload.should_not be_updated
        end
      end
    end

  end

  describe "when the association is a joined through" do
    class HasOneThroughObservableTest < ObservableAbstractTest
      self.table_name ='association_polymorphic_observable_tests'
      belongs_to :has_one_observable_test
      has_one :observer_test, :through => :has_one_observable_test
      attr_accessible :has_one_observable_test
    end

    class HasOneObservableTest < ObservableAbstractTest
      has_one :has_one_through_observable_test
      attr_accessible :has_one_through_observable_test
    end

    class ObserverTest < ObserverAbstractTest
      has_one :has_one_through_observable_test, :through => :has_one_observable_test
      attr_accessible :has_one_through_observable_test
      observes :has_one_through_observable_test, :notifiers => :test_update, :on => :update
    end

    ActiveRecord::Schema.define do
      add_column :association_polymorphic_observable_tests, :has_one_observable_test_id, :integer
    end

    let(:through_observable) { HasOneThroughObservableTest.create(:has_one_observable_test => HasOneObservableTest.new(:observer_test => ObserverTest.new)) }
    let(:observer) {through_observable.has_one_observable_test.observer_test}
    describe "when the has one association is updated" do
      before(:each) do
        observer.update_attributes(:updated => nil)
        through_observable.reload
        through_observable.update_attributes(:name => "doof")
      end
      it "should update its observer" do
        through_observable.name.should == "doof"
        observer.reload.should be_updated
      end
    end

  end

  # TODO: should this be responsibility of the associations or from the observers? check further into this
  pending "when an observable also observes its observer" do
    ActiveRecord::Schema.define do
      add_column :association_observable_tests, :successful, :boolean
    end
    before(:all) do
      class HasOneObservableTest < ObservableAbstractTest
        observes :observer_test, :notifiers => :test_update, :on => :update
      end
    end
    describe "when something changes on the observable" do
      before(:each) do
        observer1.has_one_observable_test.update_attributes(:name => "doof")
      end
      it "should update only the observer (and therefore avoid infinite cycle)" do
        observer1.has_one_observable_test.name.should == "doof"
        observer1.reload.should be_updated
      end
    end
  end

end