# -*- encoding : utf-8 -*-
require 'rubygems'
require './lib/association_observers'

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

