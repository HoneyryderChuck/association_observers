# -*- encoding : utf-8 -*-
module AssociationObservers
  def self.initialize_railtie
    ActiveSupport.on_load :active_record do
      include AssociationObservers
      #require 'association_observers/active_record'
    end
    # ORM Adapters
    #require 'association_observers/data_mapper' if defined?(DataMapper)

  end
  class Railtie < Rails::Railtie
    config.association_observers = ActiveSupport::OrderedOptions.new.merge(AssociationObservers::options)
    config.association_observers.queue = ActiveSupport::OrderedOptions.new.merge(config.association_observers.queue)

    initializer 'association_observers.insert_into_orm' do
      AssociationObservers.initialize_railtie
    end
    initializer 'association_observers.autoload', :before => :set_autoload_paths do |app|
      app.config.autoload_paths << Rails.root.join("app", "notifiers")
    end
    initializer 'association_observers.rails_configuration_options' do
      AssociationObservers::options.merge!(config.association_observers)
      AssociationObservers::queue.initialize_queue_engine
    end
  end
end