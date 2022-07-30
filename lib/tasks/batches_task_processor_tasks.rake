# frozen_string_literal: true

namespace :batches_task_processor do
  desc 'Starts the Batches Task Processor'
  task call: :environment do
    BatchesTaskProcessor::Processor.new(ENV['RUNNER_MODEL_ID']).call
  end

  desc 'Starts the Batches Task Processor'
  task process_job: :environment do
    BatchesTaskProcessor::Processor.new(ENV['RUNNER_MODEL_ID']).process_job(ENV['RUNNER_JOB_NO'])
  end


  desc 'Prints the status of the Task Processor'
  task status: :environment do
    BatchesTaskProcessor::Processor.new(ENV['RUNNER_MODEL_ID']).status
  end

  desc 'Cancels the Batches Task Processor'
  task cancel: :environment do
    BatchesTaskProcessor::Processor.new(ENV['RUNNER_MODEL_ID']).cancel
  end
end
