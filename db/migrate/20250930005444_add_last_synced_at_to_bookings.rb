class AddLastSyncedAtToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :last_synced_at, :datetime
  end
end
