module Schedules
  class BookingsController < ApplicationController
    allow_unauthenticated_access

    def index
      month = params[:month].to_i
      year = params[:year].to_i
      timezone =  params[:timezone] || Time.zone.name

      bookings = BookingService.fetch_monthly_bookings(month, year, timezone)
      render json: BookingBlueprint.render_as_hash(bookings), status: :ok
    end

    def new
      @bookings = Booking.new
    end

    def create
      service = BookingService.new(booking_params)
      result = service.create_booking

      if result[:status] == "success"
        AppointmentMailer.new_appointment(result[:booking], result[:show_url]).deliver_later
        render json: result, status: :created
      elsif result[:status] == "conflict"
        render json: result, status: :conflict
      else
        render json: result, status: :unprocessable_entity
      end
    end

    private

    def booking_params
      params.require(:booking).permit(:name, :email, :date, :start_time, :end_time, :timezone_offset, :subject, :description)
    end
  end
end
