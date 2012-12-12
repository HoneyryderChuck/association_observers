# -*- encoding : utf-8 -*-
# Default Observer which propagates notifications to the observers' observers
#
# @author Tiago Cardoso
class PropagationNotifier < Notifier::Base

  def conditions(observer) ; observer.observable? ; end
  def conditions_many(observers) ;  observers.klass.observable? ; end

  # propagates the message to the observer's observer if the
  # observer is indeed observed by any entity
  def action(observable, observer, callback=@callback)
    observer.new_record? or not observer.respond_to?(:delay) ? observer.send(:notify_observers, callback) : observer.delay.notify_observers(callback)
  end

end