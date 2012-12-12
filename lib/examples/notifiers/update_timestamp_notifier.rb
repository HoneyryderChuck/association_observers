# -*- encoding : utf-8 -*-
class UpdateTimestampNotifier < Notifier
  module ObserverMethods
    def irrelevant_observer_method
      puts "irrelevantimus"
    end
  end

  module ObservableMethods
    def irrelevant_observable_method
      puts "up yours"
    end
  end

  def action(observable, observer)
    observer.touch :timestamp
  end

  private

  def notify_many(observable, many_observers)
    unless observable.new_record?
      many_observers.each do |observers|
        observers.update_all(observers.table[:timestamp].eq(Time.now).to_sql)
      end
    end
  end

end