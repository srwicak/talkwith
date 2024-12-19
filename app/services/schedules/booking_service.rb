module Schedules
  class BookingService
    attr_reader :params

    def initialize(params)
      @params = params
    end

    # Returns all bookings that fall within the given month and year.
    #
    # The timezone parameter is required and is used to determine the start and end times of the month.
    #
    # Note that the month and year are limited to valid values (1-12 for month, and 2023 and up for year).
    # If the given values are out of range, the method will use the current month and year.
    def self.fetch_monthly_bookings(month, year, timezone)
      month = Time.zone.now.month if month < 1 || month > 12
      year = Time.zone.now.year if year < 2023

      Time.use_zone(timezone) do
        start_of_month = Time.zone.local(year, month).beginning_of_month
        end_of_month = start_of_month.end_of_month
        Booking.where(start_time: start_of_month..end_of_month)
      end
    end

    # Creates a booking based on the given params.
    #
    # Returns a hash with the following key-value pairs:
    # - `status`: String, one of "success", "conflict", or "failed".
    # - `message`: String, a message describing the result of the booking creation.
    # - `booking`: Booking, the created booking object, or nil if the booking creation failed.
    # - `show_url`: String, the URL of the created booking, or nil if the booking creation failed.
    # - `errors`: Array<String>, an array of error messages if the booking creation failed.
    def create_booking
      converted_params = convert_booking_times
      booking = Booking.new(converted_params)

      if booking.valid? && booking.save
        {
          status: "success",
          message: "Booking created successfully",
          booking: booking,
          show_url: Rails.application.routes.url_helpers.appointment_url(booking.slug)
        }
      elsif booking.errors[:base].include?("Booking overlaps with an approved schedule")
        {
          status: "conflict",
          message: "Booking overlaps with an approved schedule",
          errors: booking.errors.full_messages
        }
      else
        {
          status: "failed",
          message: "Failed to create booking",
          errors: booking.errors.full_messages
        }
      end
    end

    private

    # Converts the booking start_time and end_time to UTC
    # If timezone param is present, it will be used to convert the time
    # Otherwise, the server's timezone will be used
    #
    def convert_booking_times
      timezone = params[:timezone_offset].present? ? ActiveSupport::TimeZone[params[:timezone_offset]] : Time.zone
      date = Date.strptime(params[:date], "%m/%d/%Y")

      {
        **params.to_h.symbolize_keys,
        start_time: timezone.local_to_utc(DateTime.parse("#{date} #{params[:start_time]}")),
        end_time: timezone.local_to_utc(DateTime.parse("#{date} #{params[:end_time]}"))
      }
    end
  end
end
