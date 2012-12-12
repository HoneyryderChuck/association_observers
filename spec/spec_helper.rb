# -*- encoding : utf-8 -*-
require 'rubygems'
require 'active_record'
require './lib/association_observers'


ActiveRecord::Base.configurations = YAML.load_file(File.join(File.expand_path('../..', __FILE__), 'database.yml'))
ActiveRecord::Base.establish_connection("activerecord")


require 'rspec'
require 'database_cleaner'

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

