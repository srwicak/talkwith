module Schedules
  class AppointmentsController < ApplicationController
    allow_unauthenticated_access
    before_action :find_appointment_by_slug, only: %i[show download_ics cancel]
    before_action :verify_secret_key, only: %i[cancel download_ics]

    def show
      presenter = AppointmentPresenter.new(@appointment)
      @appointment_details = presenter.present
      puts "Appointment details: #{@appointment_details.inspect}"
    end

    def download_ics
      ics_data = IcsGeneratorService.generate(@appointment)
      send_data ics_data,
        filename: "meeting_with_#{@appointment.name.split(" ").first.downcase}_#{@appointment.start_time.strftime("%Y-%m-%d")}.ics",
        type: "text/calendar"
    end

    def cancel
      # Check if appointment is still cancellable (not in the past)
      if @appointment.start_time < Time.current
        flash[:alert] = "Cannot cancel appointments that have already started or passed."
        redirect_to appointment_path(@appointment.slug, secret_key: @appointment.secret_key)
        return
      end

      # Check if it's too close to start time (e.g., less than 2 hours)
      if @appointment.start_time < 2.hours.from_now
        flash[:alert] = "Cannot cancel appointments less than 2 hours before start time."
        redirect_to appointment_path(@appointment.slug, secret_key: @appointment.secret_key)
        return
      end

      # Store appointment data as hash before destroying
      appointment_data = {
        name: @appointment.name,
        email: @appointment.email,
        subject: @appointment.subject,
        description: @appointment.description,
        start_time: @appointment.start_time,
        end_time: @appointment.end_time,
        timezone_offset: @appointment.timezone_offset || "Asia/Jakarta"
      }
      
      # Destroy the appointment (will trigger Google Calendar removal)
      if @appointment.destroy
        # Send cancellation email with hash data
        AppointmentMailer.cancelled_appointment_with_data(appointment_data, 'user').deliver_later
        
        flash[:notice] = "Your appointment has been successfully cancelled and removed from the calendar. A confirmation email has been sent to you."
        redirect_to root_path
      else
        flash[:alert] = "Failed to cancel appointment. Please try again or contact support."
        redirect_to appointment_path(@appointment.slug, secret_key: @appointment.secret_key)
      end
    end

    private

    def find_appointment_by_slug
      @appointment = Booking.find_by(slug: params[:slug])
      unless @appointment
        render plain: "Appointment not found", status: :not_found
      end
    end

    def verify_secret_key
      unless params[:secret_key] == @appointment.secret_key
        render plain: "Invalid secret key", status: :unauthorized
      end
    end
  end
end
