class AppointmentMailer < ApplicationMailer
  default from: "MisiKangPaket <kangpaket@prangko.app>"
  
  def new_appointment(appointment, show_url)
    @appointment = appointment

    user_timezone = appointment.timezone_offset || "UTC"
    @start_time = @appointment.start_time.in_time_zone(user_timezone)
    @end_time = @appointment.end_time.in_time_zone(user_timezone)
    @name = @appointment.name.split(" ").first.titleize
    @show_url = show_url

    # Check if this is a special UDI x ITB booking
    @is_special_booking = @appointment.special_booking?

    # Different subject line for special bookings
    subject_line = if @is_special_booking
      "✅ UDI x ITB Appointment Confirmed - #{@appointment.subject}"
    else
      "⏳ Your Appointment is Saved - Pending Approval"
    end

    mail(
      to: @appointment.email,
      subject: subject_line
    )
  end

  def cancelled_appointment(appointment, cancelled_by = 'admin')
    @appointment = appointment
    @cancelled_by = cancelled_by

    user_timezone = appointment.timezone_offset || "UTC"
    @start_time = @appointment.start_time.in_time_zone(user_timezone)
    @end_time = @appointment.end_time.in_time_zone(user_timezone)
    @name = @appointment.name.split(" ").first.titleize

    # Different subject line based on who cancelled
    subject_line = if cancelled_by == 'user'
      "❌ Your Appointment Cancelled - #{@appointment.subject}"
    else
      "❌ Appointment Rejected - #{@appointment.subject}"
    end

    mail(
      to: @appointment.email,
      subject: subject_line
    )
  end

  def cancelled_appointment_with_data(appointment_data, cancelled_by = 'admin')
    @appointment_data = appointment_data
    @cancelled_by = cancelled_by

    user_timezone = appointment_data[:timezone_offset] || "UTC"
    @start_time = appointment_data[:start_time].in_time_zone(user_timezone)
    @end_time = appointment_data[:end_time].in_time_zone(user_timezone)
    @name = appointment_data[:name].split(" ").first.titleize

    # Different subject line based on who cancelled
    subject_line = if cancelled_by == 'user'
      "❌ Your Appointment Cancelled - #{appointment_data[:subject]}"
    else
      "❌ Appointment Rejected - #{appointment_data[:subject]}"
    end

    mail(
      to: appointment_data[:email],
      subject: subject_line
    ) do |format|
      format.html { render 'cancelled_appointment_with_data' }
      format.text { render 'cancelled_appointment_with_data' }
    end
  end
end
