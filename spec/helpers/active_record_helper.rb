# -*- encoding : utf-8 -*-
require 'rubygems'
require 'logger'
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ":memory:")
FileUtils.mkdir_p("log")
ActiveRecord::Base.logger = Logger.new(File.new("log/test.log", "w"))
