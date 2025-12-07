class UpdateUdiDayOfWeekToSundayStart < ActiveRecord::Migration[8.0]
  def up
    # Update day_of_week numbering system:
    # Old system: 1=Monday, 2=Tuesday, ..., 6=Saturday
    # New system: 0=Sunday, 1=Monday, ..., 6=Saturday
    #
    # Existing data (1-6 for Monday-Saturday) remains valid and compatible
    # Sunday (0) can now be added as a new configuration option
    
    say "Week system updated: Week now starts on Sunday (0) and ends on Saturday (6)"
    say "Existing UDI configurations (1-6 for Monday-Saturday) remain valid"
    say "You can now add Sunday configurations with day_of_week=0"
  end

  def down
    # This is a structural change to how weeks are calculated
    # Reverting would require changing back to Monday-based weeks
    say "To revert, manually change beginning_of_week back to :monday in booking.rb"
    say "and update DAYS constant in udi_configuration.rb"
  end
end
