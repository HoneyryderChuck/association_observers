# -*- encoding : utf-8 -*-
require "spec_helper"
require "helpers/active_record_helper"
require "helpers/delayed_job_helper"


AssociationObservers::queue.engine = :delayed_job

eval File.read(File.join(File.dirname(__FILE__), '..', 'association_observers_spec.rb'))
