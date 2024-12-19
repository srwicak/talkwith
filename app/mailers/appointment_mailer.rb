class AppointmentMailer < ApplicationMailer
  default from: "TalkWith SandyRW <talkwith@sandyrw.com>"
  def new_appointment(appointment, show_url)
    @appointment = appointment

    user_timezone = appointment.timezone_offset || "UTC"
    @start_time = @appointment.start_time.in_time_zone(user_timezone)
    @end_time = @appointment.end_time.in_time_zone(user_timezone)
    @name = @appointment.name.split(" ").first.titleize

    @show_url = show_url
    mail(
      to: @appointment.email,
      subject: "Your Appointment is saved and will be scheduled!"
    )
  end
end
