# -*- encoding : utf-8 -*-
require "logger"
require "delayed_job_active_record" if defined?(ActiveRecord)
require "delayed_job_data_mapper" if defined?(DataMapper)


FileUtils.mkdir_p("log")
Delayed::Worker.logger = Logger.new(File.new("log/delayed.log", "w"))

Delayed::Worker.delay_jobs = false

case
  when defined?(ActiveRecord)
    ActiveRecord::Schema.define do
      create_table :delayed_jobs, :force => true do |table|
        table.integer  :priority, :default => 0
        table.integer  :attempts, :default => 0
        table.text     :handler
        table.text     :last_error
        table.datetime :run_at
        table.datetime :locked_at
        table.datetime :failed_at
        table.string   :locked_by
        table.string   :queue
        table.timestamps
      end

      add_index :delayed_jobs, [:priority, :run_at], :name => 'delayed_jobs_priority'

    end
  when defined?(DataMapper)
    Delayed::Worker.backend.auto_upgrade!
end

