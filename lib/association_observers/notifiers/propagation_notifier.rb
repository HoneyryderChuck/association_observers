# -*- encoding : utf-8 -*-
# Default Observer which propagates notifications to the observers' observers
#
# @author Tiago Cardoso
class PropagationNotifier < Notifier::Base

  def conditions(observable, observer) ; observer.observable? ; end
  def conditions_many(observable, observers) ; AssociationObservers::orm_adapter.collection_class(observers).observable? ; end

  # propagates the message to the observer's observer if the
  # observer is indeed observed by any entity
  def action(observable, observer, callback=@callback)
    observer.send(:notify_observers, [callback, [@options[:observable_association_name] ] ])
  end

end