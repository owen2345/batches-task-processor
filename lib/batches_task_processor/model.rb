# frozen_string_literal: true

require 'csv'
module BatchesTaskProcessor
  class Model < ActiveRecord::Base
    self.table_name = 'batches_task_processors'
    has_many :items, class_name: 'BatchesTaskProcessor::ModelItem', dependent: :delete_all, foreign_key: :batches_task_processors_id
    validates :process_item, presence: true
    validates :key, presence: true
    before_save :apply_data_uniqueness
    before_save :check_qty_jobs
    # state: :pending, :processing, :finished, :canceled

    def qty_items_job
      @qty_items_job ||= (data.count.to_f / qty_jobs).ceil
    end

    def finish!
      update!(state: :finished, finished_at: Time.current)
    end

    def all_processed?
      items.count == data.count
    end

    # Text data columns support (Mysql only)
    def data
      self[:data].is_a?(String) ? JSON.parse(self[:data] || '[]') : self[:data]
    end

    # ********* user methods
    def start!
      Processor.new(id).call
    end

    def cancel
      update!(state: :canceled)
    end

    def status
      Rails.logger.info "Process status: #{items.count}/#{data.count}"
    end

    def retry_failures
      start!
    end

    def export
      filename = (key || 'batches_task_processor_result').try(:parameterize)
      path = Rails.root.join("tmp/#{filename}.csv")
      data = items.pluck(:key, :result, :error_details)
      data = [['Key', 'Result', 'Error details']] + data
      File.write(path, data.map(&:to_csv).join)
      Rails.logger.info "Exported to #{path}"
    end
    # ********* end user methods

    private

    def apply_data_uniqueness
      self.data = data.uniq
    end

    # Fix: at least 1 item per job
    def check_qty_jobs
      self.qty_jobs = data.count if data.count < qty_jobs
    end
  end
end
