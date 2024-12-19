module Schedules
  class AppointmentPresenter
    def initialize(appointment)
      @appointment = appointment
    end

    def present
    {
      name: formatted_name,
      date: formatted_date,
      start_time: formatted_start_time,
      end_time: formatted_end_time,
      status: formatted_status
    }
    end

    private

    def formatted_name
      @appointment.name.split(" ").first
    end

    def formatted_date
      @appointment.start_time.strftime("%A, %B %d, %Y")
    end

    def formatted_start_time
      @appointment.start_time.in_time_zone(@appointment.timezone_offset).strftime("%I:%M %p")
    end

    def formatted_end_time
      @appointment.end_time.in_time_zone(@appointment.timezone_offset).strftime("%I:%M %p")
    end

    def formatted_status
      @appointment.is_approved ? "✅ Approved" : "⌛ Pending/Under Review"
    end
  end
end
