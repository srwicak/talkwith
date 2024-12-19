class BookingBlueprint < Blueprinter::Base
  identifier :id

  fields :start_time, :end_time, :subject, :approved

  field :date do |booking|
    booking.start_time.strftime("%Y-%m-%d")
  end

  field :approved do |booking|
    booking.is_approved ? true : false
  end
end
