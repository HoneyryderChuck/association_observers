# -*- encoding : utf-8 -*-
require "./spec/helpers/active_record_helper"
require "./spec/helpers/sidekiq_helper"
require "./spec/spec_helper"

AssociationObservers::queue.engine = :sidekiq

eval File.read(File.join(File.dirname(__FILE__), '..', 'association_observers_spec.rb'))