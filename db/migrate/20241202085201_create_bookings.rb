class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :subject, null: false
      t.text :description, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :secret_key # For edit the schedule
      t.string :timezone_offset
      t.boolean :is_approved, default: false
      t.string :slug
      t.timestamps
    end
  end
end
