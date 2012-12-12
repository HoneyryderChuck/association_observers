source 'https://rubygems.org'

# Specify your gem's dependencies in association_observers.gemspec
gemspec

group :development do
  gem "yard",       "0.8.2.1", :require => false
end


platforms :ruby do
  gem 'sqlite3'
  gem 'mysql2'
  gem 'activerecord'
  gem RUBY_VERSION > "1.8.7" ? 'debugger' : 'ruby-debug'
end


platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
end
