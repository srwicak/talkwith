class CreateUdiConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :udi_configurations do |t|
      t.integer :day_of_week, null: false # 1=Monday, 2=Tuesday, ..., 6=Saturday
      t.string :start_time, null: false # Format: "08:00"
      t.string :end_time, null: false # Format: "17:00"
      t.integer :slot_duration, default: 30 # Duration in minutes
      t.integer :buffer_time, default: 5 # Buffer between slots in minutes
      t.boolean :enabled, default: true

      t.timestamps
    end

    add_index :udi_configurations, :day_of_week
    add_index :udi_configurations, :enabled
  end
end
