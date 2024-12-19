require "rails_helper"

RSpec.describe Schedules::BookingService, type: :service do
  let(:valid_booking_params) do
    {
      name: "John Doe",
      email: "john@example.com",
      date: "02/01/2025",
      start_time: "10:00 AM",
      end_time: "11:00 AM",
      timezone_offset: "UTC",
      subject: "Meeting",
      description: "Discuss project updates"
    }
  end

  describe ".fetch_monthly_bookings" do
    it "returns bookings within the specified month and year" do
      FactoryBot.create(:booking, start_time: DateTime.new(2025, 1, 1, 11, 0), end_time: DateTime.new(2025, 1, 1, 12, 0))
      bookings = Schedules::BookingService.fetch_monthly_bookings(1, 2025, "UTC")
      expect(bookings.count).to eq(1)
    end
  end

  describe "#create_booking" do
    it "creates a booking successfully" do
      service = Schedules::BookingService.new(valid_booking_params)
      result = service.create_booking

      expect(result[:status]).to eq("success")
      expect(result[:booking]).to be_persisted
    end

    it "returns conflict for overlapping bookings" do
      create(:booking, start_time: DateTime.new(2025, 2, 1, 10), end_time: DateTime.new(2025, 2, 1, 12), is_approved: true)

      params = valid_booking_params.merge(start_time: "10:30 AM", end_time: "11:30 AM")
      service = Schedules::BookingService.new(params)
      result = service.create_booking

      expect(result[:status]).to eq("conflict")
    end
  end
end
