# frozen_string_literal: true

module BatchesTaskProcessor
  class Model < ApplicationRecord
    self.table_name = 'batches_task_processors'
    has_many :items, class_name: 'BatchesTaskProcessor::ModelItem', dependent: :destroy
    # state: :pending, :processing, :finished, :canceled
    before_create :apply_data_uniqueness

    def qty_jobs
      (data.count.to_f / per_page).ceil
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