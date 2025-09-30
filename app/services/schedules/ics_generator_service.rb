module Schedules
  class IcsGeneratorService
    def self.generate(appointment)
      cal = Icalendar::Calendar.new
      
      cal.event do |e|
        e.dtstart = appointment.start_time
        e.dtend = appointment.end_time
        e.summary = appointment.subject
        
        # Enhanced description with Zoom info for special bookings
        description = appointment.description
        
        if appointment.special_booking?
          zoom_info = "\n\n" + "="*50 + "\n"
          zoom_info += "🎥 ZOOM MEETING INFORMATION\n"
          zoom_info += "="*50 + "\n"
          zoom_info += "Meeting ID: 834 951 2627\n"
          zoom_info += "Passcode: fS2XXP\n"
          zoom_info += "Join URL: https://zoom.us/j/8349512627?pwd=fS2XXP\n\n"
          zoom_info += "📝 Instructions:\n"
          zoom_info += "- Join the meeting 3 minutes early\n"
          zoom_info += "- This is a UDImpact ITB Hub 1:1 coaching session\n"
          zoom_info += "- Meeting link will be active 5 minutes before start time\n"
          zoom_info += "="*50
          
          description += zoom_info
        end
        
        e.description = description
        
        # Add location for special bookings
        if appointment.special_booking?
          e.location = "Zoom Meeting: https://zoom.us/j/8349512627?pwd=fS2XXP"
        end
        
        # Add alarm/reminder
        e.alarm do |a|
          a.action = "DISPLAY"
          a.description = "Appointment reminder"
          a.trigger = "-PT15M" # 15 minutes before
        end
        
        # Additional alarm for special bookings
        if appointment.special_booking?
          e.alarm do |a|
            a.action = "DISPLAY"
            a.description = "This is a UDImpact ITB Hub 1:1 coaching session - Join Zoom in 3 minutes"
            a.trigger = "-PT3M" # 3 minutes before
          end
        end
        
        # Add organizer using Icalendar::Values::CalAddress
        organizer = Icalendar::Values::CalAddress.new("mailto:me@sandyrw.com", cn: "Sandy R Wicaksono")
        e.organizer = organizer
        
        # Add attendee using Icalendar::Values::CalAddress
        attendee = Icalendar::Values::CalAddress.new("mailto:#{appointment.email}", cn: appointment.name, role: "REQ-PARTICIPANT")
        e.attendee = attendee
        
        # Add categories
        if appointment.special_booking?
          e.categories = ["UDI", "ITB", "Collaboration", "Auto-Approved"]
        else
          e.categories = ["Appointment", "Pending"]
        end
      end
      
      cal.to_ical
    end
  end
end
