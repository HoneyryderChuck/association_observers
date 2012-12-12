# -*- encoding : utf-8 -*-
module AssociationObservers
  def self.initialize_railtie
    ActiveSupport.on_load :active_record do
      require 'association_observers/activerecord'
    end
  end
  class Railtie < Rails::Railtie
    initializer 'association_observers.insert_into_active_record' do
      AssociationObservers.initialize_railtie
    end
    initializer 'association_observers.autoload', :before => :set_autoload_paths do |app|
      app.config.autoload_paths += Rails.root.join("app", "notifiers")
    end
  end
end