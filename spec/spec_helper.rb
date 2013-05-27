# -*- encoding : utf-8 -*-
require 'rubygems'

['data_mapper', 'active_record'].each do |orm|
  begin
    require orm
  rescue LoadError
    puts "#{orm} not available"
  end
end

require './lib/association_observers'

require 'rspec'

RSpec.configure do |config|
  config.mock_with :rspec
end

