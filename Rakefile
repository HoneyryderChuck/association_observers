require "bundler/gem_tasks"

task :default do ;; end

require 'rspec/core/rake_task'

spec_prereq = :noop

task :noop do; end

RSpec::Core::RakeTask.new(:active_record_spec => spec_prereq) do |t|
  t.rspec_opts = ['--options', "\"./.rspec\""]
  t.pattern   = "spec/activerecord/**/*_spec.rb"
end

RSpec::Core::RakeTask.new(:data_mapper_spec => spec_prereq) do |t|
  t.rspec_opts = ['--options', "\"./.rspec\""]
  t.pattern   = "spec/datamapper/**/*_spec.rb"
end

RSpec::Core::RakeTask.new(:spec => spec_prereq) do |t|
  Rake::Task["active_record_spec"].invoke rescue (failed = true)
  Rake::Task["data_mapper_spec"].invoke rescue (failed = true)
  raise "failed" if failed
end