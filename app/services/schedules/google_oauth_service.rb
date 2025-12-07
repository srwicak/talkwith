require "googleauth"
require_relative "../../../lib/json_token_store"

module Schedules
  class GoogleOauthService
    include Google::Apis::CalendarV3
    
    OOB_URI = "urn:ietf:wg:oauth:2.0:oob"  # Out-of-band (manual code entry)
    SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR
    TOKEN_PATH = Rails.root.join("config", "google_oauth_token.json")
    CREDENTIALS_PATH = Rails.root.join("config", "google_oauth_credentials.json")
    
    def initialize
      @service = CalendarService.new
      @service.authorization = authorize
    end
    
    # Create event with Google Meet in Gmail A's calendar
    def create_event_with_meet(appointment, target_calendar_id)
      Rails.logger.info "🚀 Creating event with Google Meet (OAuth2): #{appointment.subject}"
      
      event = Google::Apis::CalendarV3::Event.new
      event.summary = appointment.subject
      event.description = build_description(appointment)
      
      # Set times
      event.start = Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.start_time.iso8601,
        time_zone: appointment.timezone_offset || "Asia/Jakarta"
      )
      event.end = Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.end_time.iso8601,
        time_zone: appointment.timezone_offset || "Asia/Jakarta"
      )
      
      # Add Google Meet conference
      event.conference_data = Google::Apis::CalendarV3::ConferenceData.new(
        create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
          request_id: "#{appointment.id}-#{SecureRandom.hex(8)}",
          conference_solution_key: Google::Apis::CalendarV3::ConferenceSolutionKey.new(
            type: 'hangoutsMeet'
          )
        )
      )
      
      # Set reminders
      event.reminders = Google::Apis::CalendarV3::Event::Reminders.new(
        use_default: false,
        overrides: [
          Google::Apis::CalendarV3::EventReminder.new(
            reminder_method: 'popup',
            minutes: 15
          ),
          Google::Apis::CalendarV3::EventReminder.new(
            reminder_method: 'popup',
            minutes: 5
          )
        ]
      )
      
      # Create event with conference data
      result = @service.insert_event(
        target_calendar_id,
        event,
        conference_data_version: 1,
        send_updates: "none"
      )
      
      Rails.logger.info "✅ Created event with Meet: #{result.id}"
      
      # Extract Google Meet link
      meet_link = extract_meet_link(result)
      if meet_link
        Rails.logger.info "🎥 Google Meet link: #{meet_link}"
        appointment.update_column(:meeting_link, meet_link)
      end
      
      result.id
    rescue Google::Apis::Error => e
      Rails.logger.error "❌ OAuth2 API Error: #{e.message}"
      nil
    end
    
    # Update event
    def update_event(event_id, appointment, target_calendar_id)
      event = @service.get_event(target_calendar_id, event_id)
      
      event.summary = appointment.subject
      event.description = build_description(appointment)
      event.start.date_time = appointment.start_time.iso8601
      event.end.date_time = appointment.end_time.iso8601
      
      result = @service.update_event(
        target_calendar_id,
        event_id,
        event,
        send_updates: "none"
      )
      
      # Update meet link if changed
      meet_link = extract_meet_link(result)
      appointment.update_column(:meeting_link, meet_link) if meet_link
      
      Rails.logger.info "✅ Updated event: #{event_id}"
    rescue Google::Apis::Error => e
      Rails.logger.error "❌ Failed to update event: #{e.message}"
      false
    end
    
    # Check if OAuth is configured
    def self.configured?
      File.exist?(CREDENTIALS_PATH)
    end
    
    # Check if user has authorized
    def self.authorized?
      File.exist?(TOKEN_PATH)
    end
    
    # Get authorization URL for first-time setup
    def self.authorization_url
      return nil unless configured?
      
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = JsonTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      authorizer.get_authorization_url(base_url: OOB_URI)
    end
    
    # Store authorization code
    def self.store_authorization_code(code)
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = JsonTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      
      credentials = authorizer.get_credentials_from_code(
        user_id: 'default',
        code: code,
        base_url: OOB_URI
      )
      
      if credentials
        token_store.store('default', credentials)
        true
      else
        false
      end
    end
    
    private
    
    def authorize
      unless File.exist?(CREDENTIALS_PATH)
        raise "OAuth2 credentials not found. Please add #{CREDENTIALS_PATH}"
      end
      
      client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
      token_store = JsonTokenStore.new(file: TOKEN_PATH)
      authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
      
      credentials = authorizer.get_credentials('default')
      
      unless credentials
        raise "No authorization found. Please run OAuth2 setup first."
      end
      
      # Refresh token if needed
      if credentials.expired?
        credentials.refresh!
      end
      
      credentials
    end
    
    def extract_meet_link(event)
      return nil unless event.conference_data&.entry_points&.any?
      
      video_entry = event.conference_data.entry_points.find { |ep| ep.entry_point_type == 'video' }
      video_entry&.uri
    end
    
    def build_description(appointment)
      description = appointment.description.to_s
      
      description += "\n\n👤 ATTENDEE INFORMATION"
      description += "\nName: #{appointment.name}"
      description += "\nEmail: #{appointment.email}"
      
      if appointment.special_booking?
        description += "\n\n🎥 UDI x ITB Hub 1:1 Coaching Session"
        description += "\nGoogle Meet link available in this event"
      end
      
      description += "\n\n📧 Contact: me@sandyrw.com"
      description += "\n🌐 TalkWith"
      
      description
    end
  end
end
