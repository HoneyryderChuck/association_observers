if defined?(ActiveRecord)
  ActiveRecord::Base.send(:extend, AssociationObservers::ClassMethods)
  ActiveRecord::Base.send(:include, AssociationObservers::InstanceMethods)
end