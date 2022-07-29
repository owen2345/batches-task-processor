# frozen_string_literals: true

require 'rails'
module BatchesTaskProcessor
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/batches_task_processor_tasks.rake'
    end
  end
end
