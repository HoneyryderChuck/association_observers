# -*- encoding : utf-8 -*-
# Default Observer which propagates notifications to the observers' observers
#
# @author Tiago Cardoso
class PropagationNotifier < Notifier::Base

  def conditions(observable, observer) ; observer.observable? ; end
  def conditions_many(observable, observers) ; observers.send(AssociationObservers::orm_adapter.fetch_model_from_collection).observable? ; end

  # propagates the message to the observer's observer if the
  # observer is indeed observed by any entity
  def action(observable, observer, callback=@callback)
    (observer.send(AssociationObservers::orm_adapter.check_new_record_method) or not observer.respond_to?(:delay)) ? observer.send(:notify_observers, callback) : observer.delay.notify_observers(callback)
  end

end