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

    # Create event in Google Calendar
    def create_event(appointment)
      Rails.logger.info "Creating Google Calendar event for: #{appointment.subject}"
      
      event = Google::Apis::CalendarV3::Event.new(
        summary: appointment.subject,
        description: build_description(appointment),
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: appointment.start_time.iso8601,
          time_zone: appointment.timezone_offset || "Asia/Jakarta"
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: appointment.end_time.iso8601,
          time_zone: appointment.timezone_offset || "Asia/Jakarta"
        ),
        # IMPORTANT: No attendees for Service Account!
        # Attendee info is included in description instead
        reminders: Google::Apis::CalendarV3::Event::Reminders.new(
          use_default: true
        )
      )

      # Use send_updates: "none" to avoid attendee invitation issues
      result = @service.insert_event(calendar_id, event, send_updates: "none")
      Rails.logger.info "✅ Created Google Calendar event: #{result.id} for appointment: #{appointment.subject}"
      result.id
    rescue Google::Apis::ClientError => e
      if e.message.include?("forbiddenForServiceAccounts")
        Rails.logger.error "❌ Service Account cannot invite attendees. Error: #{e.message}"
      else
        Rails.logger.error "❌ Google Calendar API Error: #{e.message}"
      end
      nil
    rescue => e
      Rails.logger.error "❌ Unexpected error creating calendar event: #{e.message}"
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
        description += "\nMeeting ID: 834-951-2627"
        description += "\nPasscode: fS2XXP"
        description += "\nJoin URL: https://zoom.us/j/8349512627?pwd=fS2XXP"
      end
      
      description += "\n\n📧 Contact: me@sandyrw.com"
      description += "\n🌐 TalkWith Sandy R Wicaksono"
      
      description
    end
  end
end