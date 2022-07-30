# frozen_string_literal: true

require "batches_task_processor/version"
require "batches_task_processor/railtie"
require "batches_task_processor/processor"
require "../lib/models/batches_task_processor/model"
require "../lib/models/batches_task_processor/model_item"

module BatchesTaskProcessor
  class Config
    cattr_accessor(:process_item) { -> (_item, _process_model) { raise('Implement calculate_items method') } }
    cattr_accessor(:preload_job_items) { -> (items, _process_model) { items } }

    def self.configure
      yield self
    end
  end
end
