# frozen_string_literals: true

require 'rails'
module BatchesTaskProcessor
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load 'tasks/batches_task_processor_tasks.rake'
    end
    initializer :append_migrations do |app|
      path = File.join(File.expand_path('../../', __FILE__), 'db/migrate')
      app.config.paths["db/migrate"] << path
    end
  end
end
