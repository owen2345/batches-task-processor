# BatchesTaskProcessor
Gem that allows to process huge amount of tasks in parallel using batches (Supports for array or activerecord collections).

## Installation
Add this line to your application's Gemfile:

```ruby
gem "batches_task_processor"
```
And then execute: `bundle install`


## Usage
- Register a new task: 
  `task = BatchesTaskProcessor::Model.create!(key: 'my_process', data: [1, 2, 3], per_page: 5000)`
  Activerecord sample:
  `process_model = BatchesTaskProcessor::Model.create!(key: 'my_process', data: Article.pluck(:id), per_page: 5000)`

- Create an initializer file for your application:    
  Sample Array:    
  ```ruby
    # config/initializers/batches_task_processor.rb
    require 'batches_task_processor'
    BatchesTaskProcessor::Config.configure do |config|
      config.preload_job_items = -> { |items, process_model| Article.where(id: items) }
      config.process_item = -> { |item, process_model| MyService.new.process(item) }
    end
  ```
- Run the corresponding rake task:     
  Copy the `process_model.id` from step one and use it in the following code:    
  `RUNNER_MODEL_ID=<id-here> rake batches_task_processor:call`

## Api
Settings:    
- `config.process_item(item)` (Mandatory) method called to process each item
- `config.preload_job_items(items)` (Optional) Allows to preload associations or load objects list. Provides `items` which is a chunk of items to process.

Tasks (requires `RUNNER_MODEL_ID` env variable):    
- `rake batches_task_processor:call` Starts the processing of jobs.
- `rake batches_task_processor:status` Prints the process status.
- `rake batches_task_processor:cancel` Marks as cancelled the process and stops processing jobs.

## TODO
- Update tests to use ActiveRecord

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
