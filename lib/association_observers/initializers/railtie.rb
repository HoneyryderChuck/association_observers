# -*- encoding : utf-8 -*-
module AssociationObservers
  def self.initialize_railtie
    ActiveSupport.on_load :active_record do
      require 'association_observers/active_record'
    end
    # ORM Adapters
    require 'association_observers/data_mapper' if defined?(DataMapper)

    # Background Processing Queue Adapters
    require 'association_observers/initializers/delayed_job' if defined?(Delayed)
    require 'association_observers/initializers/resque' if defined?(Resque)
    require 'association_observers/initializers/sidekiq' if defined?(Sidekiq)
  end
  class Railtie < Rails::Railtie
    initializer 'association_observers.insert_into_orm' do
      AssociationObservers.initialize_railtie
    end
    initializer 'association_observers.autoload', :before => :set_autoload_paths do |app|
      app.config.autoload_paths << Rails.root.join("app", "notifiers")
    end
  end
end