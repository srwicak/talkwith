class SyncGoogleCalendarJob < ApplicationJob
  queue_as :default
  
  def perform(booking)
    # Check if this is a special booking (UDI) and OAuth is configured
    if booking.special_booking? && Schedules::GoogleOauthService.authorized?
      # Use OAuth2 service for UDI bookings (creates real Google Meet)
      begin
        sync_with_oauth(booking)
      rescue => e
        Rails.logger.error "❌ OAuth sync failed, falling back to Service Account: #{e.message}"
        # Fallback to service account if OAuth fails
        sync_with_service_account(booking)
      end
    else
      # Use service account for regular bookings
      sync_with_service_account(booking)
    end
  rescue => e
    Rails.logger.error "❌ Failed to sync booking #{booking.id} with Google Calendar: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
  
  private
  
  def sync_with_oauth(booking)
    Rails.logger.info "🔐 Using OAuth2 for UDI booking #{booking.id}"
    
    oauth_service = Schedules::GoogleOauthService.new
    calendar_id = Rails.application.credentials.dig(:google, :calendar_id)
    
    if booking.google_calendar_event_id.present?
      # Update existing event
      if oauth_service.update_event(booking.google_calendar_event_id, booking, calendar_id)
        booking.update_column(:last_synced_at, Time.current)
        Rails.logger.info "✅ Updated OAuth event for booking #{booking.id}"
      end
    else
      # Create new event with Google Meet
      event_id = oauth_service.create_event_with_meet(booking, calendar_id)
      if event_id
        booking.update_columns(
          google_calendar_event_id: event_id,
          last_synced_at: Time.current
        )
        Rails.logger.info "✅ Created OAuth event with Meet for booking #{booking.id}"
      else
        Rails.logger.error "❌ Failed to create OAuth event for booking #{booking.id}"
      end
    end
  end
  
  def sync_with_service_account(booking)
    Rails.logger.info "🔧 Using Service Account for booking #{booking.id}"
    
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