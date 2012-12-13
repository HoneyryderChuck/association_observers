# -*- encoding : utf-8 -*-
require 'rubygems'
require 'data_mapper'
require 'dm-observer'

DataMapper.setup(:default, 'mysql://root:@127.0.0.1/association_observers')
