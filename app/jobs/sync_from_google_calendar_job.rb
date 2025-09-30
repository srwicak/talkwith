class SyncFromGoogleCalendarJob < ApplicationJob
  queue_as :default
  
  def perform
    Rails.logger.info "Starting Google Calendar sync..."
    
    begin
      google_service = Schedules::GoogleCalendarService.new
      
      # Use proper Time objects instead of strings
      time_min = Time.current.beginning_of_day
      time_max = 2.months.from_now.end_of_day
      
      Rails.logger.info "Fetching events from #{time_min} to #{time_max}"
      events = google_service.fetch_events(time_min, time_max)
      
      synced_count = 0
      updated_count = 0
      
      events.each do |event|
        begin
          Rails.logger.debug "Processing event: #{event.id} - #{event.summary}"
          
          # Skip events without proper time information
          next unless event.start&.date_time && event.end&.date_time
          
          # Parse times safely
          start_time = parse_google_time(event.start.date_time)
          end_time = parse_google_time(event.end.date_time)
          
          next unless start_time && end_time
          
          # Extract event details
          summary = event.summary || "Google Calendar Event"
          description = event.description || ""
          
          # Get attendee information (now allows events without attendees)
          attendee_info = extract_attendee_info(event)
          next unless attendee_info
          
          # Check if booking already exists
          existing_booking = Booking.find_by(google_calendar_event_id: event.id)
          
          if existing_booking
            # Check if Google Calendar event was updated after our last sync
            event_updated = event.updated.to_time
            booking_last_synced = existing_booking.last_synced_at || existing_booking.updated_at
            
            if event_updated > booking_last_synced
              # Update existing booking (Google Calendar has priority)
              result_booking = update_existing_booking(existing_booking, event, summary, description, start_time, end_time)
              if result_booking
                updated_count += 1
                Rails.logger.info "Updated booking #{existing_booking.id} - Google Calendar was newer"
              end
            else
              Rails.logger.debug "Skipping booking #{existing_booking.id} - no changes detected since last sync"
            end
          else
            # Create new booking
            result_booking = create_new_booking(event, summary, description, start_time, end_time, attendee_info)
            if result_booking
              synced_count += 1
            end
          end
          
        rescue => e
          Rails.logger.error "Error processing event #{event.id}: #{e.message}"
          next # Continue with next event
        end
      end
      
      Rails.logger.info "Google Calendar sync complete: #{synced_count} new, #{updated_count} updated"
      
    rescue => e
      Rails.logger.error "Failed to sync from Google Calendar: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
  
  private
  
  def parse_google_time(time_obj)
    return nil unless time_obj
    
    if time_obj.respond_to?(:to_time)
      time_obj.to_time
    else
      Time.parse(time_obj.to_s)
    end
  rescue
    nil
  end
  
  def extract_attendee_info(event)
    # If no attendees, use organizer email (buat event sendiri)
    if !event.attendees&.any?
      Rails.logger.info "No attendees found, using organizer as attendee"
      return {
        name: "Me",
        email: "me@sandyrw.com"
      }
    end
    
    # Find first attendee that's not the organizer
    attendee = event.attendees.find { |a| a.email != "me@sandyrw.com" }
    
    if attendee
      {
        name: attendee.display_name || attendee.email.split('@')[0].humanize,
        email: attendee.email
      }
    else
      # If all attendees are organizer, use first attendee
      first_attendee = event.attendees.first
      {
        name: first_attendee.display_name || first_attendee.email.split('@')[0].humanize,
        email: first_attendee.email
      }
    end
  end
  
  def update_existing_booking(booking, event, summary, description, start_time, end_time)
    # Set date for validation (Booking model requires it)
    date_for_validation = start_time.strftime("%m/%d/%Y")
    
    # Update booking with latest data from Google Calendar (Google Calendar has priority)
    if booking.update(
      subject: summary,
      description: description,
      start_time: start_time,
      end_time: end_time,
      date: date_for_validation,
      timezone_offset: event.start.time_zone || "Asia/Jakarta",
      is_approved: true, # Ensure it stays approved
      last_synced_at: Time.current # Track when we last synced
    )
      Rails.logger.info "Updated booking #{booking.id} from Google event #{event.id}: #{summary}"
      booking
    else
      Rails.logger.error "Failed to update booking #{booking.id} from Google event #{event.id}: #{booking.errors.full_messages}"
      nil
    end
  end
  
  def create_new_booking(event, summary, description, start_time, end_time, attendee_info)
    # Set date for validation (Booking model requires it)
    date_for_validation = start_time.strftime("%m/%d/%Y")
    
    # Ensure name is at least 3 characters
    safe_name = attendee_info[:name].to_s.length >= 3 ? attendee_info[:name] : "Google Calendar User"
    
    booking = Booking.new(
      name: safe_name,
      email: attendee_info[:email],
      subject: summary,
      description: description,
      start_time: start_time,
      end_time: end_time,
      timezone_offset: event.start.time_zone || "Asia/Jakarta",
      is_approved: true,
      google_calendar_event_id: event.id,
      date: date_for_validation,
      last_synced_at: Time.current # Track when we created this from sync
    )
    
    # Skip most validations since this comes from Google Calendar (trusted source)
    booking.save(validate: false)
    
    if booking.persisted?
      Rails.logger.info "Created booking #{booking.id} from Google event #{event.id}"
      booking
    else
      Rails.logger.error "Failed to create booking from Google event #{event.id}: #{booking.errors.full_messages}"
      nil
    end
  end
end