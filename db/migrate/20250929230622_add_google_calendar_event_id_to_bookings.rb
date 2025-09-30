class AddGoogleCalendarEventIdToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :google_calendar_event_id, :string
    add_index :bookings, :google_calendar_event_id
  end
end
