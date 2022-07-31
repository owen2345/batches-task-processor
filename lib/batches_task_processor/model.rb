# frozen_string_literal: true

module BatchesTaskProcessor
  class Model < ActiveRecord::Base
    self.table_name = 'batches_task_processors'
    has_many :items, class_name: 'BatchesTaskProcessor::ModelItem', dependent: :destroy, foreign_key: :batches_task_processors_id
    validate :process_item, presence: true
    validate :key, presence: true
    before_create :apply_data_uniqueness
    # state: :pending, :processing, :finished, :canceled

    def qty_items_job
      @qty_items_job ||= (data.count.to_f / qty_jobs).ceil
    end

    def finish!
      update!(state: :finished, finished_at: Time.current)
    end

    def cancel!
      update!(state: :canceled)
    end

    def all_processed?
      items.count == data.count
    end

    private

    def apply_data_uniqueness
      self.data = data.uniq
    end
  end
end
