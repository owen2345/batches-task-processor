# frozen_string_literal: true

namespace :batches_task_processor do
  desc 'Starts the Batches Task Processor'
  task call: :environment do
    BatchesTaskProcessor::Processor.new(ENV['RUNNER_TASK_ID']).call
  end

  desc 'Starts the Batches Task Processor'
  task process_job: :environment do
    BatchesTaskProcessor::Processor.new(ENV['RUNNER_TASK_ID']).process_job(ENV['RUNNER_JOB_NO'])
  end
end
