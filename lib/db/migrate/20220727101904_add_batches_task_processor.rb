# frozen_string_literal: true

class AddBatchesTaskProcessor < ActiveRecord::Migration[5.0]
  def change
    create_table :batches_task_processors do |t|
      t.string :key
      t.string :state, default: :pending
      t.json :data, default: []
      t.integer :qty_jobs, default: 10
      t.datetime :finished_at
      t.text :preload_job_items
      t.text :process_item, null: false
      t.timestamps
    end

    create_table :batches_task_processor_items do |t|
      t.belongs_to :batches_task_processors, foreign_key: true, index: { name: 'index_batches_task_processors_parent_id' }
      t.string :key
      t.text :result
      t.text :error_details
      t.timestamps
    end
  end
end
