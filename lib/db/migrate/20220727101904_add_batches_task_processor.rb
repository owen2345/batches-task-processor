# frozen_string_literal: true

class AddBatchesTaskProcessor < ActiveRecord::Migration[5.0]
  def change
    create_table :batches_task_processors do |t|
      t.string :key
      t.string :state, default: :pending
      t.json :data, default: []
      t.integer :per_page, default: 5000
      t.datetime :finished_at
      t.timestamps
    end

    create_table :batches_task_processor_items do |t|
      t.belongs_to :batch_task_processor, foreign_key: true
      t.string :key
      t.text :result
      t.text :error_details
      t.timestamps
    end
  end
end
