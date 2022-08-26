# frozen_string_literal: true

require 'active_support/all'
module BatchesTaskProcessor
  class Processor
    attr_reader :task_id

    def initialize(task_id = nil)
      @task_id = task_id || ENV['RUNNER_TASK_ID']
    end

    def call
      init_jobs
    end

    def process_job(job_no)
      run_job(job_no.to_i)
    end

    private

    # @example item.perform_my_action
    def process_item(item)
      instance_eval(task_model.process_item)
    end

    # @example Article.where(no: items)
    def preload_job_items(items)
      instance_eval(task_model.preload_job_items || 'items')
    end

    def init_jobs
      jobs = task_model.qty_jobs
      log "Initializing #{jobs} jobs..."
      jobs.times.each do |index|
        if task_model.queue_name
          log "Scheduling ##{index} job..."
          BatchesTaskProcessor::ProcessorJob.set(queue: task_model.queue_name).perform_later(task_id, index)
        else
          start_inline_job(index)
        end
      end
    end

    def start_inline_job(job_no)
      log "Starting ##{job_no} job..."
      env_vars = "RUNNER_JOB_NO=#{job_no} RUNNER_TASK_ID=#{task_id}"
      pid = Process.spawn("#{env_vars} rake batches_task_processor:process_job &")
      Process.detach(pid)
    end

    def run_job(job)
      log "Running ##{job} job..."
      items = job_items(job)
      (items.try(:find_each) || items.each).with_index(1) do |item, index|
        key = item.try(:id) || item
        break log('Process cancelled') if process_cancelled?
        next if already_processed?(key)

        start_process_item(item, job, key, index)
      end

      log "Finished #{job} job..."
      task_model.finish! if task_model.all_processed?
    end

    def job_items(job)
      res = task_model.data.each_slice(task_model.qty_items_job).to_a[job]
      preload_job_items(res)
    end

    def start_process_item(item, job, key, index)
      log "Processing key: #{key}, job: #{job}, counter: #{index}/#{task_model.qty_items_job}"
      result = process_item(item)
      task_model.items.where(key: key).first_or_initialize.update!(result: result, error_details: nil)
    rescue => e
      task_model.items.where(key: key).first_or_initialize.update!(result: nil, error_details: e.message)
      log "Process failed #{job}/#{key}: #{e.message}"
    end

    def already_processed?(key)
      task_model.items.where(key: key, error_details: nil).exists?
    end

    def process_cancelled?
      task_model.state == 'cancelled'
    end

    def log(msg)
      puts "BatchesTaskProcessor => #{msg}"
    end

    def task_model
      klass = BatchesTaskProcessor::Model.all
      task_id ? klass.find(task_id) : klass.last
    end
  end
end
