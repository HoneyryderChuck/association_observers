# -*- encoding : utf-8 -*-
module AssociationObservers
  def self.initialize_railtie
    ActiveSupport.on_load :active_record do
      require 'association_observers/activerecord'
    end
  end
  class Railtie < Rails::Railtie
    initializer 'default_value_for.insert_into_active_record' do
      AssociationObservers.initialize_railtie
    end
  end
end