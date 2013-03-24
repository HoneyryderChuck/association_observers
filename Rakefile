require "bundler/gem_tasks"

task :default do ;; end

require 'rspec/core/rake_task'


RSpec::Core::RakeTask.new(:active_record_spec) do |t|
  t.rspec_opts = ['--options', "\"./.rspec\""]
  t.pattern   = "spec/activerecord/*_spec.rb"
end

RSpec::Core::RakeTask.new(:active_record_delayed_job_spec) do |t|
  t.rspec_opts = ['--options', "\"./.rspec\""]
  t.pattern   = "spec/activerecord/delayed_job/*_spec.rb"
end

RSpec::Core::RakeTask.new(:active_record_resque_spec) do |t|
  t.rspec_opts = ['--options', "\"./.rspec\""]
  t.pattern   = "spec/activerecord/resque/*_spec.rb"
end

RSpec::Core::RakeTask.new(:data_mapper_spec) do |t|
  t.rspec_opts = ['--options', "\"./.rspec\""]
  t.pattern   = "spec/datamapper/*_spec.rb"
end

task :spec do |t|
  Rake::Task["active_record_spec"].invoke rescue (failed = true)
  Rake::Task["active_record_delayed_job_spec"].invoke rescue (failed = true)
  Rake::Task["active_record_resque_spec"].invoke rescue (failed = true)
  Rake::Task["data_mapper_spec"].invoke rescue (failed = true)
  raise "failed" if failed
end