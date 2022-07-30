# frozen_string_literal: true

module BatchesTaskProcessor
  class ModelItem < ActiveRecord::Base
    self.table_name = 'batches_task_processor_items'
    belongs_to :parent, class_name: 'BatchesTaskProcessor::Model'
  end
end
