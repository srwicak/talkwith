#!/usr/bin/env ruby

# Debug script untuk Google Calendar sync
# Jalankan dengan: bin/rails runner bin/debug_google_calendar.rb

puts "🔍 Google Calendar Debug Script"
puts "=" * 50

# Test Google Calendar Service
begin
  service = Schedules::GoogleCalendarService.new
  puts "✅ Google Calendar Service initialized"
  
  # Fetch events
  events = service.fetch_events
  puts "📅 Found #{events.length} events in Google Calendar"
  
  events.each_with_index do |event, i|
    puts "\n#{i+1}. #{event.summary}"
    puts "   ID: #{event.id}"
    puts "   Start: #{event.start.date_time}"
    puts "   End: #{event.end.date_time}"
    puts "   Attendees: #{event.attendees&.length || 0}"
    if event.attendees&.any?
      event.attendees.each do |attendee|
        puts "     - #{attendee.email} (#{attendee.display_name})"
      end
    end
  end
  
rescue => e
  puts "❌ Error with Google Calendar Service: #{e.message}"
end

puts "\n" + "=" * 50

# Test Database
puts "📊 Database Status:"
total_bookings = Booking.count
approved_bookings = Booking.where(is_approved: true).count
synced_bookings = Booking.where.not(google_calendar_event_id: nil).count

puts "   Total bookings: #{total_bookings}"
puts "   Approved bookings: #{approved_bookings}"
puts "   Synced to Google Calendar: #{synced_bookings}"

if synced_bookings > 0
  puts "\n📋 Synced Bookings:"
  Booking.where.not(google_calendar_event_id: nil).each do |booking|
    puts "   #{booking.subject} (#{booking.google_calendar_event_id})"
  end
end

puts "\n🔧 Manual Commands:"
puts "   # Test sync FROM Google Calendar:"
puts "   SyncFromGoogleCalendarJob.perform_now"
puts ""
puts "   # Test sync TO Google Calendar:"
puts "   booking = Booking.where(is_approved: true, google_calendar_event_id: nil).first"
puts "   SyncGoogleCalendarJob.perform_now(booking) if booking"
puts ""
puts "   # Create test booking:"
puts "   Booking.create!(name: 'Test User', email: 'test@example.com', subject: 'Test Meeting', description: 'Test', start_time: 1.hour.from_now, end_time: 2.hours.from_now, date: Date.tomorrow.strftime('%m/%d/%Y'), timezone_offset: 'Asia/Jakarta', is_approved: true)"