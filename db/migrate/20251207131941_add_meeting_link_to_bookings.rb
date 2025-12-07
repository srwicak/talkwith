class AddMeetingLinkToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :meeting_link, :string
  end
end
