# frozen_string_literal: true

namespace :batches_task_processor do
  desc 'Starts the Batches Task Processor'
  task call: :environment do
    BatchesTaskProcessor::Processor.new.call
  end

  desc 'Starts the Batches Task Processor'
  task process_job: :environment do
    BatchesTaskProcessor::Processor.new.process_job(ENV['RUNNER_JOB_NO'])
  end

  desc 'Retries the Batches Task Processor'
  task retry: :environment do
    BatchesTaskProcessor::Processor.new.retry
  end

  desc 'Prints the status of the Task Processor'
  task status: :environment do
    BatchesTaskProcessor::Processor.new.status
  end

  desc 'Cancels the Batches Task Processor'
  task cancel: :environment do
    BatchesTaskProcessor::Processor.new.cancel
  end

  desc 'Clears the Batches Task Processor cache'
  task clear: :environment do
    BatchesTaskProcessor::Processor.new.clear
  end
end
