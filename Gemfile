source 'https://rubygems.org'
gemspec

group :development do
  gem "yard",       "0.8.2.1", :require => false
end

gem 'activerecord'
gem 'datamapper'

platforms :ruby do
  gem 'mysql2'
  gem 'dm-mysql-adapter'
end


platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-mysql'
end
