# -*- encoding : utf-8 -*-
require 'rubygems'
require 'active_record'
require 'logger'
ActiveRecord::Base.configurations = YAML.load_file(File.join(File.expand_path('../../..', __FILE__), 'database.yml'))
ActiveRecord::Base.establish_connection("activerecord")
FileUtils.mkdir_p("log")
ActiveRecord::Base.logger = Logger.new(File.new("log/test.log", "w"))
