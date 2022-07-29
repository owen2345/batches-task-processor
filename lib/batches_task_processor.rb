require "batches_task_processor/version"
require "batches_task_processor/railtie"
require "batches_task_processor/processor"


module BatchesTaskProcessor
  class Config
    cattr_accessor(:per_page) { 5000 }
    cattr_accessor(:calculate_items) { -> { raise('Implement calculate_items method') } }
    cattr_accessor(:process_item) { -> (_item) { raise('Implement calculate_items method') } }
    cattr_accessor(:preload_job_items) { -> (items) { items } }


    def self.configure
      yield self
    end
  end
end
