# BatchesTaskProcessor
Gem that allows to process huge amount of tasks in parallel using batches (Supports for array or activerecord collections).    
This gem depends on `Rails.cache` to save results of processing (In the future: use a database table instead).

## Installation
Add this line to your application's Gemfile:

```ruby
gem "batches_task_processor"
```
And then execute: `bundle install`


## Usage
- Create an initializer file for your application:    
  Sample Array:    
  ```ruby
    # config/initializers/batches_task_processor.rb
    BatchesTaskProcessor::Config.configure do |config|
      config.per_page = 100
      config.calculate_items = -> { [1,2,3,5] }
      config.preload_job_items = -> { |items| Article.where(id: items) }
      config.process_item = -> { |item| MyService.new.process(item) }
    end
  ```
  Sample ActiveRecord Collection:
    ```ruby
      # config/initializers/batches_task_processor.rb
      BatchesTaskProcessor::Config.configure do |config|
        config.per_page = 100
        config.calculate_items = -> { Article.where(created_at: 10.days.ago..Time.current) }
        config.process_item = -> { |item| MyService.new.process(item) }
      end
    ```

## Api
Settings:    
- `config.calculate_items` (Mandatory) method called to calculate the whole list of items to process
- `config.process_item(item)` (Mandatory) method called to process each item
- `config.per_page` (Optional) number of items in one batch
- `config.preload_job_items(items)` (Optional) Allows to preload associations or load objects list. Provides `items` which is a chunk of items to process.
Tasks:    
- `rake batches_task_processor:call` Starts the processing of jobs.
- `rake batches_task_processor:process_job` (Only for internal usage). 
- `rake batches_task_processor:retry` Retries the processing of all jobs (ignores already processed).
- `rake batches_task_processor:status` Prints the process status.
- `rake batches_task_processor:cancel` Marks as cancelled the process and stops processing jobs.
- `rake batches_task_processor:clear` Removes all process logs or tmp data.


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
