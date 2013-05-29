source 'https://rubygems.org'
gemspec

group :development do
  gem "yard",       "0.8.2.1", :require => false
end

group :test do
  #gem "delayed_job_data_mapper",                          :require => false
  gem "delayed_job_active_record",                        :require => false
  gem "resque",                                           :require => false
  gem "sidekiq",                                          :require => false unless RUBY_VERSION == "1.8.7"
end

platforms :ruby do
  gem "sqlite3"
end

platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
end
