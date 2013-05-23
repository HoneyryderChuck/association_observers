# -*- encoding : utf-8 -*-
require "helpers/active_record_helper"
require "helpers/resque_helper"
require "spec_helper"

AssociationObservers::queue.engine = :resque

eval File.read(File.join(File.dirname(__FILE__), '..', 'association_observers_spec.rb'))
