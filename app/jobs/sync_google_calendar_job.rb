class SyncGoogleCalendarJob < ApplicationJob
  queue_as :default
  
  def perform(booking)
    google_service = Schedules::GoogleCalendarService.new
    
    if booking.google_calendar_event_id.present?
      # Update existing event
      if google_service.update_event(booking.google_calendar_event_id, booking)
        booking.update_column(:last_synced_at, Time.current)
        Rails.logger.info "✅ Updated Google Calendar event for booking #{booking.id}"
      end
    else
      # Create new event
      event_id = google_service.create_event(booking)
      if event_id
        booking.update_columns(
          google_calendar_event_id: event_id,
          last_synced_at: Time.current
        )
        Rails.logger.info "✅ Created Google Calendar event #{event_id} for booking #{booking.id}"
      else
        Rails.logger.error "❌ Failed to create Google Calendar event for booking #{booking.id}"
      end
    end
  rescue => e
    Rails.logger.error "❌ Failed to sync booking #{booking.id} with Google Calendar: #{e.message}"
    # You might want to retry or send notification to admin here
  end
end