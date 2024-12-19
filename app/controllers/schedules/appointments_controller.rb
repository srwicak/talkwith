module Schedules
  class AppointmentsController < ApplicationController
    allow_unauthenticated_access
    before_action :find_appointment_by_slug, only: %i[show download_ics]

    def show
      presenter = AppointmentPresenter.new(@appointment)
      @appointment_details = presenter.present
      puts "Appointment details: #{@appointment_details.inspect}"
    end

    def download_ics
      if params[:secret_key] != @appointment.secret_key
        render plain: "Invalid secret key", status: :unauthorized
      else
        ics_data = IcsGeneratorService.generate(@appointment)
        send_data ics_data,
          filename: "meeting_with_#{@appointment.name.split(" ").first.downcase}_#{@appointment.start_time.strftime("%Y-%m-%d")}.ics",
          type: "text/calendar"
      end
    end

    private

    def find_appointment_by_slug
      @appointment = Booking.find_by(slug: params[:slug])
      render_not_found unless @appointment
    end
  end
end
