module Schedules
  class IcsGeneratorService
    def self.generate(appointment)
      cal = Icalendar::Calendar.new
      
      cal.event do |e|
        e.dtstart = appointment.start_time
        e.dtend = appointment.end_time
        e.summary = appointment.subject
        
        # Enhanced description with meeting info for special bookings
        description = appointment.description
        
        if appointment.special_booking?
          meeting_info = "\n\n" + "="*50 + "\n"
          meeting_info += "🎥 MEETING INFORMATION\n"
          meeting_info += "="*50 + "\n"
          
          if appointment.meeting_link.present?
            meeting_info += "Google Meet: #{appointment.meeting_link}\n\n"
          else
            meeting_info += "Meeting link will be sent via email shortly\n\n"
          end
          
          meeting_info += "📝 Instructions:\n"
          meeting_info += "- Join the meeting 5-10 minutes early\n"
          meeting_info += "- This is a UDI x ITB Hub 1:1 coaching session\n"
          meeting_info += "- Meeting link will be active 15 minutes before start time\n"
          meeting_info += "="*50
          
          description += meeting_info
        end
        
        e.description = description
        
        # Add location for special bookings
        if appointment.special_booking?
          if appointment.meeting_link.present?
            e.location = "Google Meet: #{appointment.meeting_link}"
            e.url = Icalendar::Values::Uri.new(appointment.meeting_link)
          else
            e.location = "Google Meet (link will be sent)"
          end
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
            a.description = "This is a UDI x ITB Hub 1:1 coaching session - Join Google Meet in 5 minutes"
            a.trigger = "-PT5M" # 5 minutes before
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
