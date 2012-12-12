source 'https://rubygems.org'
gemspec

group :development do
  gem "yard",       "0.8.2.1", :require => false
end

gem 'activerecord'
gem 'sqlite3'

platforms :ruby do
  gem RUBY_VERSION > "1.8.7" ? 'debugger' : 'ruby-debug'
  gem 'mysql2'
end


platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-mysql'
end
