module Schedules
  class IcsGeneratorService
    def self.generate(appointment)
      cal = Icalendar::Calendar.new
      cal.event do |e|
        e.dtstart = appointment.start_time
        e.dtend = appointment.end_time
        e.summary = appointment.subject
        e.description = appointment.description
      end
      cal.to_ical
    end
  end
end
