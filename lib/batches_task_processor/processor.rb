# frozen_string_literal: true

require 'active_support/all'
module BatchesTaskProcessor
  class Processor
    RUNNER_JOB_KEY = 'RUNNER_JOB_KEY'
    attr_reader :model_id

    def initialize(model_id = nil)
      @model_id = model_id || ENV['RUNNER_MODEL_ID']
    end

    def call
      init_jobs
    end

    def process_job(job_no)
      run_job(job_no.to_i)
    end

    def status
      log "Process status: #{process_model.items.count}/#{process_model.data.count}"
    end

    def cancel
      process_model.cancel!
    end

    private

    # @example item.perform_my_action
    def process_item(item)
      instance_exec(item, process_model, &BatchesTaskProcessor::Config.process_item)
    end

    # @example Article.where(no: items)
    def preload_job_items(items)
      instance_exec(items, process_model, &BatchesTaskProcessor::Config.preload_job_items)
    end

    def init_jobs
      jobs = process_model.qty_jobs
      log "Initializing #{jobs} jobs..."
      jobs.times.each do |index|
        log "Starting ##{index} job..."
        env_vars = "RUNNER_JOB_NO=#{index} RUNNER_MODEL_ID=#{model_id}"
        pid = Process.spawn("#{env_vars} rake batches_task_processor:process_job &")
        Process.detach(pid)
      end
    end

    def run_job(job)
      log "Running ##{job} job..."
      preload_job_items(job_items(job)).each_with_index do |item, index|
        key = item.try(:id) || item
        break log('Process cancelled') if process_cancelled?
        next log("Skipping #{key}...") if already_processed?(key)

        start_process_item(item, job, key, index)
      end

      log "Finished #{job} job..."
      process_model.finish! if process_model.all_processed?
    end

    def job_items(job)
      process_model.data.each_slice(process_model.per_page).to_a[job]
    end

    def start_process_item(item, job, key, index)
      log "Processing #{job}/#{key}: #{index}/#{per_page}"
      result = process_item(item)
      process_model.items.create!(key: key, result: result.to_s[0..255])
    rescue => e
      process_model.items.create!(key: key, error_details: e.message)
      log "Process failed #{job}/#{key}: #{e.message}"
    end

    def already_processed?(key)
      process_model.items.where(key: key).exists?
    end

    def process_cancelled?
      process_model.state == 'cancelled'
    end

    def log(msg)
      puts "BatchesTaskProcessor => #{msg}"
    end

    def process_model
      klass = BatchesTaskProcessor::Model.all
      model_id ? klass.where(id: model_id) : klass.last
    end
  end
end
