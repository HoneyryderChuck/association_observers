# -*- encoding : utf-8 -*-
require 'rubygems'
require 'active_record'
require './lib/association_observers'


ActiveRecord::Base.configurations = YAML.load_file(File.join(File.expand_path('../..', __FILE__), 'database.yml'))
ActiveRecord::Base.establish_connection("activerecord")


require 'rspec'
require 'database_cleaner'
require 'webmock'
require 'delayed_job'
require 'delayed_job_active_record'

class Delayed::Backend::ActiveRecord::Job
 after_create do |job|
   job = self.class.find(job.id) # make db roundtrip
   job.invoke_job
   job.destroy
 end
end

RSpec.configure do |config|

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.mock_with :rspec
end

