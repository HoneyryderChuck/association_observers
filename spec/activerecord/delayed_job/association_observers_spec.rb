# -*- encoding : utf-8 -*-
require "./spec/helpers/active_record_helper"
require "./spec/helpers/delayed_job_helper"
require "./spec/spec_helper"

AssociationObservers::queue.engine = :delayed_job

eval File.read(File.join(File.dirname(__FILE__), '..', 'association_observers_spec.rb'))
