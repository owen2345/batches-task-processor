# frozen_string_literal: true

class AddBatchesTaskProcessor < ActiveRecord::Migration[5.0]
  def change
    create_table :batches_task_processors do |t|
      t.string :key
      t.string :state, default: :pending
      t.json :data, default: [] if support_json?
      t.text :data, limit: 999999 unless support_json?
      t.integer :qty_jobs, default: 10
      t.datetime :finished_at
      t.text :preload_job_items
      t.text :process_item, null: false
      t.string :queue_name, default: :default
      t.timestamps
    end

    create_table :batches_task_processor_items do |t|
      t.belongs_to :batches_task_processors, foreign_key: true, index: { name: 'index_batches_task_processors_parent_id' }
      t.string :key
      t.text :result, limit: 999999
      t.text :error_details
      t.timestamps
    end
  end

  def support_json?
    connector_name = ActiveRecord::Base.connection.adapter_name.downcase
    no_json = connector_name.include?('mysql') || connector_name.include?('sqlite')
    !no_json
  end
end
