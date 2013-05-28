# -*- encoding : utf-8 -*-
shared_examples_for "example using observers" do
  let(:observer1) {create_model(ObserverTest, :has_one_observable_test => HasOneObservableTest.new,
                                              :has_many_observable_tests => [HasManyObservableTest.new,
                                                                             HasManyObservableTest.new,
                                                                             HasManyObservableTest.new])}
  let(:observer2) { create_model(ObserverTest) }
  let(:belongs_to_observable) {build_model(BelongsToObservableTest, :observer_test => observer1)}
  let(:collection_observable) {create_model(CollectionObservableTest, :observer_tests => [observer1, observer2])}
  let(:polymorphic_observable) {create_model(PolymorphicHasManyObservableTest, :observer => observer2)}
  before(:all) do
    puts $queue_engine
    AssociationObservers::queue.engine = $queue_engine unless $queue_engine.nil?
  end
  after(:all) do
    puts "done: #{$queue_engine}"
    unless $queue_engine.nil?
      AssociationObservers::queue.finalize_engine
      $queue_engine = nil
    end
  end
  before do
    observer1.belongs_to_observable_test = belongs_to_observable
    observer1.save
  end
  describe "observer_methods" do
    let(:observer) { build_model(ObserverObserverTest) }
    it "should be available" do
      observer.should be_observer
      observer.should_not be_observable
    end
  end

  describe "observable_methods" do
    let(:observable){ build_model(BelongsToObservableTest) }
    it "should be available" do
      observable.should_not be_observer
      observable.should be_observable
    end
  end

  describe "when the belongs to observable is updated" do
    before(:each) do
      update_model(belongs_to_observable, :name => "doof")
    end
    it "should update its observer" do
      belongs_to_observable.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when the observable hides itself" do
    before(:each) do
      update_model!(observer1, :updated => nil)
      belongs_to_observable.unobservable!
      update_model(belongs_to_observable, :name => "doof")
    end
    it "should not update its observer" do
      observer1.belongs_to_observable_test.name.should == "doof"
      observer1.reload.should_not be_updated
    end
  end
  describe "when the has one observable is updated" do
    before(:each) do
      update_model(observer1.has_one_observable_test, :name => "doof")
    end
    it "should update its observer" do
      observer1.has_one_observable_test.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when one of the has many observables is updated" do
    before(:each) do
      update_model(observer1.has_many_observable_tests.first, :name => "doof")
    end
    it "should update its observer" do
      observer1.has_many_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
    describe "and afterwards deleted" do
      before(:each) do
        update_model!(observer1, :deleted => false)
        observer1.has_many_observable_tests.first.destroy
      end
      it "should update its observer" do
        observer1.reload.should be_deleted
      end
    end
  end
  if defined?(PolymorphicHasManyObservableTest)
    describe "when one of the polymorphic has many is updated" do
      before(:each) do
        observer1.polymorphic_has_many_observable_tests = [PolymorphicHasManyObservableTest.new,
                                                           PolymorphicHasManyObservableTest.new,
                                                           PolymorphicHasManyObservableTest.new]
        update_model!(observer1, :updated => false)
        observer1.reload
      end
      it "should update its observer" do
        update_model(observer1.polymorphic_has_many_observable_tests.first, :name => "doof")
        observer1.polymorphic_has_many_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer1.should_not be_deleted
      end
      describe "having another polymorphic observable of same type somewhere else" do
        before(:each) do
          update_model!(observer2, :updated => false)
        end
        it "should not update its observer" do
          update_model(observer1.polymorphic_has_many_observable_tests.first, :name => "doof")
          observer1.polymorphic_has_many_observable_tests.first.name.should == "doof"
          observer1.reload.should be_updated
          observer1.should_not be_deleted
          observer2.reload.should_not be_updated
          observer2.should_not be_deleted
        end
      end
    end
  end
  describe "when the has many through has been updated" do
    before(:each) do
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.create
      update_model!(observer1, :updated => false)
    end
    it "should update its observer" do
      update_model(observer1.has_many_observable_tests.first.has_many_through_observable_tests.first, :name => "doof")
      observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.name.should == "doof"
      observer1.reload.should be_updated
      observer1.should_not be_deleted
    end
  end
  describe "when the collection observable is updated" do
    before(:each) do
      update_model(collection_observable, :name => "doof")
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
      update_model(observer1, :observer_observer_test => observer_observer)
    end
    describe "when the belongs to observable is updated" do
      before(:each) do
        update_model(belongs_to_observable, :name => "doof")
      end
      it "should update its observer and its observer's observer" do
        belongs_to_observable.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the has one observable is updated" do
      before(:each) do
        update_model(observer_observer.observer_test.has_one_observable_test, :name => "doof")
      end
      it "should update its observer and its observer's observer" do
        observer_observer.observer_test.has_one_observable_test.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when one of the has many observables is updated" do
      before(:each) do
        update_model(observer_observer.observer_test.has_many_observable_tests.first, :name => "doof")
      end
      it "should update its observer and its observer's observer" do
        observer_observer.observer_test.has_many_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    if defined?(PolymorphicHasManyObservableTest)
      describe "when one of the polymorphic has many is updated" do
        before(:each) do
          observer1.polymorphic_has_many_observable_tests = [PolymorphicHasManyObservableTest.new,
                                                             PolymorphicHasManyObservableTest.new,
                                                             PolymorphicHasManyObservableTest.new]
          update_model!(observer1, :updated => false)
          update_model!(observer_observer, :updated => false)
        end
        it "should update its observer" do
          update_model(observer_observer.observer_test.polymorphic_has_many_observable_tests.first, :name => "doof")
          observer_observer.observer_test.polymorphic_has_many_observable_tests.first.name.should == "doof"
          observer1.reload.should be_updated
          observer_observer.reload.should be_updated
        end
      end
    end
    describe "when the has many through has been updated" do
      before(:each) do
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.create
        update_model!(observer1, :updated => false)
        update_model!(observer_observer, :updated => false)
      end
      it "should update its observer" do
        update_model(observer1.has_many_observable_tests.first.has_many_through_observable_tests.first, :name => "doof")
        observer1.has_many_observable_tests.first.has_many_through_observable_tests.first.name.should == "doof"
        observer1.reload.should be_updated
        observer_observer.reload.should be_updated
      end
    end
    describe "when the collection observable is updated" do
      before(:each) do
        collection_observable
        update_model(observer_observer.observer_test.reload.collection_observable_test, :name => "doof")
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
      create_model(ManyObserverObserverTest, :observer_test => observer1)
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
        update_model(belongs_to_observable, :name => "doof")
      end
    end
  end

  if defined?(HasOnePolymorphicObservableTest)
    describe "when the association is polymorphic" do
      let(:polymorphic_observable) { create_model(HasOnePolymorphicObservableTest, :observer => ObserverTest.new) }
      let(:observer) {polymorphic_observable.observer}
      before(:each) do
        update_model!(observer, :updated => nil)
      end
      describe "when the has one association is updated" do
        before(:each) do
          update_model(polymorphic_observable, :name => "doof")
        end
        it "should update its observer" do
          polymorphic_observable.name.should == "doof"
          observer.reload.should be_updated
        end
      end
      describe "when the observable is not observed" do
        let(:other_polymorphic_observable) { create_model(HasOnePolymorphicObservableTest, :observer => OtherPossibleObserverTest.new) }
        let(:non_observer){ other_polymorphic_observable.observer }
        describe " and the observable is updated" do
          before(:each) do
            update_model(other_polymorphic_observable, :name => "doof")
          end
          it "should not update its (non) observer" do
            other_polymorphic_observable.name.should == "doof"
            non_observer.reload.should_not be_updated
          end
        end
      end
    end
  end

  describe "when the association is a joined through" do
    let(:through_observable) { create_model(HasOneThroughObservableTest, :has_one_observable_test => HasOneObservableTest.new(:observer_test => ObserverTest.new)) }
    let(:observer) {through_observable.has_one_observable_test.observer_test}
    describe "when the has one association is updated" do
      before(:each) do
        update_model(observer, :updated => nil)
        update_model(through_observable, :name => "doof")
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
        update_model(observer1.has_one_observable_test, :name => "doof")
      end
      it "should update only the observer (and therefore avoid infinite cycle)" do
        observer1.has_one_observable_test.name.should == "doof"
        observer1.reload.should be_updated
      end
    end
  end

end