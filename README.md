# BatchesTaskProcessor
Ruby Gem that allows to process huge amount of any kind of tasks in parallel using batches with the ability to cancel at any time. 
The jobs created can be processed in background or in the foreground (inline) with the ability to rerun/retry later (excludes the already processed ones).

## Installation
Add this line to your application's Gemfile:

```ruby
gem "batches_task_processor"
```
And then execute: `bundle install && bundle exec rake db:migrate`

## Usage 
- Register a new task:     
  The following will process 200k items with 10 jobs parallelly each one in charge of 20k items (recommended `preload_job_items` for performance reasons):
  ```ruby
  task = BatchesTaskProcessor::Model.create!(
    key: 'my_process',
    data: Article.all.limit(200000).pluck(:id),
    qty_jobs: 10,
    preload_job_items: 'Article.where(id: items)',
    process_item: 'puts "my article ID: #{item.id}"'
  )
  task.start!
  ```
![Photo](./img.png)

## Task api  
  - `task.start!` starts the task (initializes the jobs)
  - `task.cancel` cancels the task at any time and stops processing the items
  - `task.export` exports the items that were processed in a csv file
  - `task.items` returns the items that were processed so far       
    Each item includes the following attributes: `# { key: 'value from items', result: "value returned from the process_item callback", error_details: "error message from the process_message callback if failed" }`

## TODO
- update tests

## Api
Settings:    
- `data` (Array<Integer|String>) Array of whole items to be processed.
- `key` (Mandatory) key to be used to identify the task.
- `queue_name` (String, default `default`) name of the background queue to be used (If `nil`, will run the process inline).
- `qty_jobs` (Optional) number of jobs to be created (all `data` items will be distributed across this qty of jobs). Default: `10`
- `process_item` (Mandatory) callback to be called to perform each item where `item` variable holds the current item value. Sample: `'Article.find(item).update_column(:title, "changed")'`
- `preload_job_items` (Optional) callback that allows to preload items list and/or associations where `items` variable holds the current chunk of items to be processed (by default returns the same list). Sample: `Article.where(id: items)`

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
