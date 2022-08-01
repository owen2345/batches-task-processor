# frozen_string_literal: true

module BatchesTaskProcessor
  class ProcessorJob < ActiveJob::Base
    queue_as :default

    def perform(task_id, job_no)
      Processor.new(task_id).process_job(job_no)
    end
  end
end
