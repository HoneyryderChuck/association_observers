# -*- encoding : utf-8 -*-
require "helpers/resque_helper"
require "spec_helper"
require "helpers/active_record_helper"

AssociationObservers::queue.engine = :resque

eval File.read(File.join(File.dirname(__FILE__), '..', 'association_observers_spec.rb'))
