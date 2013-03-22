# -*- encoding : utf-8 -*-
module AssociationObservers
  def self.initialize_railtie
    ActiveSupport.on_load :active_record do
      require 'association_observers/active_record'
    end
    ActiveSupport.on_load :data_mapper do
      require 'association_observers/data_mapper'
    end
    ActiveSupport.on_load :delayed_job do
      require 'association_observers/delayed_job'
    end
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