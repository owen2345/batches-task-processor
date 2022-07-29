require_relative "lib/batches_task_processor/version"

Gem::Specification.new do |spec|
  spec.name        = "batches_task_processor"
  spec.version     = BatchesTaskProcessor::VERSION
  spec.authors     = ["Owen Peredo"]
  spec.email       = ["owenperedo@gmail.com"]
  spec.homepage    = "https://github.com/owen2345/batches-task-processor"
  spec.summary     = "Gem that allows to process huge amount of tasks in parallel using batches"
  spec.description = spec.summary
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # spec.metadata["allowed_push_host"] = ""

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails"
end
