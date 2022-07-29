# frozen_string_literal: true

require 'active_support/all'
module BatchesTaskProcessor
  class Processor
    RUNNER_JOB_KEY = 'RUNNER_JOB_KEY'

    def call
      init_cache
      init_jobs
    end

    def process_job(job_no)
      run_job(job_no.to_i, calculate_items)
    end

    def retry
      init_jobs
    end

    def status
      res = Rails.cache.read(RUNNER_JOB_KEY)
      res[:jobs] = res[:jobs].times.map { |i| job_registry(i)[:items].count }
      puts "Process status: #{res.inspect}"
    end

    def cancel
      data = Rails.cache.read(RUNNER_JOB_KEY)
      data[:cancelled] = true
      Rails.cache.write(RUNNER_JOB_KEY, data)
    end

    def clear
      res = Rails.cache.read(RUNNER_JOB_KEY)
      res[:jobs].times.each { |i| job_registry(i, :delete) }
      Rails.cache.delete(RUNNER_JOB_KEY)
    end

    private

    # ****** customizations
    # @example ['article_id1', 'article_id2', 'article_id3']
    # @example Article.where(created_at: 1.month_ago..Time.current)
    def calculate_items
      instance_exec(&BatchesTaskProcessor::Config.calculate_items)
    end

    # @example item.perform_my_action
    def process_item(item)
      instance_exec(item, &BatchesTaskProcessor::Config.process_item)
    end

    def per_page
      BatchesTaskProcessor::Config.per_page
    end

    # @example Article.where(no: items)
    def preload_job_items(items)
      instance_exec(items, &BatchesTaskProcessor::Config.preload_job_items)
    end
    # ****** end customizations

    def init_cache
      items = calculate_items
      jobs = (items.count.to_f / per_page).ceil
      data = { jobs: jobs, count: items.count, date: Time.current, finished_jobs: [], cancelled: false }
      main_registry(data)
    end

    def init_jobs
      jobs = main_registry[:jobs]
      log "Initializing #{jobs} jobs..."
      jobs.times.each do |index|
        log "Starting ##{index} job..."
        pid = Process.spawn("RUNNER_JOB_NO=#{index} rake batches_task_processor:process_job &")
        Process.detach(pid)
      end
    end

    def run_job(job, items)
      log "Running ##{job} job..."
      preload_job_items(job_items(items, job)).each_with_index do |item, index|
        key = item.try(:id) || item
        break log('Process cancelled') if process_cancelled?
        next log("Skipping #{key}...") if already_processed?(job, key)

        start_process_item(item, job, key, index)
      end

      mark_finished_job(job)
      log "Finished #{job} job..."
    end

    def job_items(items, job)
      items.is_a?(Array) ? items.each_slice(per_page).to_a[job] : items.offset(job * per_page).limit(per_page)
    end

    def start_process_item(item, job, key, index)
      log "Processing #{job}/#{key}: #{index}/#{per_page}"
      process_item(item)
      update_job_cache(job, key)
    rescue => e
      update_job_cache(job, key, e.message)
      log "Process failed #{job}/#{key}: #{e.message}"
    end

    def main_registry(new_data = nil)
      Rails.cache.write(RUNNER_JOB_KEY, new_data, expires_in: 1.week) if new_data
      new_data || Rails.cache.read(RUNNER_JOB_KEY)
    end

    def mark_finished_job(job)
      main_registry(main_registry.merge(finished_jobs: main_registry[:finished_jobs] + [job]))
    end

    def job_registry(job, new_data = nil)
      key = "#{RUNNER_JOB_KEY}/#{job}"
      default_data = { items: [], errors: [] }
      Rails.cache.write(key, default_data, expires_in: 1.week) unless Rails.cache.read(key)
      Rails.cache.write(key, new_data, expires_in: 1.week) if new_data
      Rails.cache.delete(key) if new_data == :delete
      new_data || Rails.cache.read(key)
    end

    def update_job_cache(job, value, error = nil)
      data = job_registry(job)
      data[:items] << value
      data[:errors] << [value, error] if error
      job_registry(job, data)
    end

    def already_processed?(job, value)
      job_registry(job)[:items].include?(value)
    end

    def process_cancelled?
      Rails.cache.read(RUNNER_JOB_KEY)[:cancelled]
    end

    def log(msg)
      puts "BatchesTaskProcessor => #{msg}"
    end
  end
end
