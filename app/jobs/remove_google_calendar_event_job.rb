class RemoveGoogleCalendarEventJob < ApplicationJob
  queue_as :default
  
  def perform(google_event_id)
    google_service = Schedules::GoogleCalendarService.new
    google_service.delete_event(google_event_id)
  rescue => e
    Rails.logger.error "Failed to remove Google Calendar event #{google_event_id}: #{e.message}"
    # You might want to send notification to admin here
  end
end