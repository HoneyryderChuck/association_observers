# -*- encoding : utf-8 -*-
require 'rubygems'
require 'data_mapper'

datamapper_config = YAML.load_file(File.join(File.expand_path('../..', __FILE__), 'database.yml'))["datamapper"]

DataMapper.setup(:default, datamapper_config)
