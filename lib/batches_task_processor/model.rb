# frozen_string_literal: true

require 'csv'
module BatchesTaskProcessor
  class Model < ActiveRecord::Base
    self.table_name = 'batches_task_processors'
    has_many :items, class_name: 'BatchesTaskProcessor::ModelItem', dependent: :destroy, foreign_key: :batches_task_processors_id
    validates :process_item, presence: true
    validates :key, presence: true
    before_create :apply_data_uniqueness
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

    # ********* user methods
    def start!
      Processor.new(id).call
    end

    def cancel
      update!(state: :canceled)
    end

    def status
      log "Process status: #{task_model.items.count}/#{task_model.data.count}"
    end

    def export
      path = Rails.root.join('tmp/batches_task_processor_result.csv')
      data = items.pluck(:key, :result, :error_details)
      data = [['Key', 'Result', 'Error details']] + data
      File.write(path, data.map(&:to_csv).join)
      log "Exported to #{path}"
    end
    # ********* end user methods

    private

    def apply_data_uniqueness
      self.data = data.uniq
    end
  end
end
