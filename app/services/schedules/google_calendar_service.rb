require "google/apis/calendar_v3"
require "googleauth"

module Schedules
  class GoogleCalendarService
    include Google::Apis::CalendarV3
    
    def initialize
      @service = CalendarService.new
      @service.authorization = authorize
      validate_calendar_setup
    end

    # Create event in Google Calendar - FIXED VERSION
    def create_event(appointment)
      Rails.logger.info "🚀 Creating Google Calendar event for: #{appointment.subject}"
      
      # Create event object with proper array fields
      event = Google::Apis::CalendarV3::Event.new
      event.summary = appointment.subject
      event.description = build_description(appointment)
      
      # Set start time
      event.start = Google::Apis::CalendarV3::EventDateTime.new
      event.start.date_time = appointment.start_time.iso8601
      event.start.time_zone = appointment.timezone_offset || "Asia/Jakarta"
      
      # Set end time  
      event.end = Google::Apis::CalendarV3::EventDateTime.new
      event.end.date_time = appointment.end_time.iso8601
      event.end.time_zone = appointment.timezone_offset || "Asia/Jakarta"
      
      # Set reminders
      event.reminders = Google::Apis::CalendarV3::Event::Reminders.new
      event.reminders.use_default = true
      
      # CRITICAL: Explicitly ensure attendees is empty array instead of nil
      event.attendees = []
      
      # Also ensure other array fields are properly initialized
      event.recurrence = [] if event.recurrence.nil?
      
      Rails.logger.info "📤 Event object created - Attendees: #{event.attendees.inspect}"
      
      # Create the event with explicit send_updates: "none"
      result = @service.insert_event(calendar_id, event, send_updates: "none")
      Rails.logger.info "✅ Successfully created Google Calendar event: #{result.id}"
      result.id
    rescue Google::Apis::ClientError => e
      if e.message.include?("forbiddenForServiceAccounts")
        Rails.logger.error "❌ Service Account attendee error: #{e.message}"
      else
        Rails.logger.error "❌ Google Calendar API Error: #{e.message}"
      end
      nil
    rescue => e
      Rails.logger.error "❌ Unexpected error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      nil
    end

    # Update event in Google Calendar
    def update_event(google_event_id, appointment)
      event = @service.get_event(calendar_id, google_event_id)
      
      event.summary = appointment.subject
      event.description = build_description(appointment)
      event.start = Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.start_time.iso8601,
        time_zone: appointment.timezone_offset || "Asia/Jakarta"
      )
      event.end = Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.end_time.iso8601,
        time_zone: appointment.timezone_offset || "Asia/Jakarta"
      )

      @service.update_event(calendar_id, google_event_id, event, send_updates: "none")
      Rails.logger.info "Updated Google Calendar event: #{google_event_id} for appointment: #{appointment.subject}"
    rescue Google::Apis::Error => e
      Rails.logger.error "Google Calendar API Error: #{e.message}"
      false
    end

    # Delete event from Google Calendar
    def delete_event(google_event_id)
      @service.delete_event(calendar_id, google_event_id, send_updates: "all")
    rescue Google::Apis::Error => e
      Rails.logger.error "Google Calendar API Error: #{e.message}"
      false
    end

    # Fetch events from Google Calendar
    def fetch_events(time_min = nil, time_max = nil)
      raise "Calendar ID not configured" if calendar_id.blank?
      
      # Set default time range if not provided
      time_min ||= Time.current.beginning_of_day
      time_max ||= 2.months.from_now.end_of_day
      
      Rails.logger.info "Fetching events from #{calendar_id} between #{time_min} and #{time_max}"
      
      @service.list_events(
        calendar_id,
        single_events: true,
        order_by: 'startTime',
        time_min: time_min.iso8601,
        time_max: time_max.iso8601
      ).items || []
    rescue Google::Apis::Error => e
      Rails.logger.error "Google Calendar API Error: #{e.message}"
      Rails.logger.error "Calendar ID: #{calendar_id}"
      []
    end

    private

    def calendar_id
      @calendar_id ||= Rails.application.credentials.dig(:google, :calendar_id)
    end

    def validate_calendar_setup
      if calendar_id.blank?
        raise "Google Calendar ID not configured. Please set google.calendar_id in Rails credentials."
      end
      
      Rails.logger.info "Google Calendar Service initialized with calendar: #{calendar_id}"
    end

    def authorize
      scope = Google::Apis::CalendarV3::AUTH_CALENDAR
      
      credentials_path = Rails.root.join("config", "google_service_account.json")
      unless File.exist?(credentials_path)
        raise "Google service account file not found at: #{credentials_path}"
      end
      
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(credentials_path),
        scope: scope
      )
      
      authorizer.fetch_access_token!
      authorizer
    end

    def build_description(appointment)
      description = appointment.description.to_s
      
      # Add attendee information to description since we can't invite attendees with Service Account
      description += "\n\n👤 ATTENDEE INFORMATION"
      description += "\nName: #{appointment.name}"
      description += "\nEmail: #{appointment.email}"
      
      if appointment.special_booking?
        description += "\n\n🎥 ZOOM MEETING INFORMATION"
        description += "\nMeeting ID: 834 951 2627"
        description += "\nPasscode: fS2XXP"
        description += "\nJoin URL: https://zoom.us/j/8349512627?pwd=fS2XXP"
      end
      
      description += "\n\n📧 Contact: me@sandyrw.com"
      description += "\n🌐 TalkWith Sandy R Wicaksono"
      
      description
    end
  end
end