# == Schema Information
#
# Table name: bookings
#
#  id                       :integer          not null, primary key
#  description              :text             not null
#  email                    :string           not null
#  end_time                 :datetime         not null
#  is_approved              :boolean          default(FALSE)
#  last_synced_at           :datetime
#  name                     :string           not null
#  secret_key               :string
#  slug                     :string
#  start_time               :datetime         not null
#  subject                  :string           not null
#  timezone_offset          :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  google_calendar_event_id :string
#
# Indexes
#
#  index_bookings_on_google_calendar_event_id  (google_calendar_event_id)
#
#  id              :integer          not null, primary key
#  description     :text             not null
#  email           :string           not null
#  end_time        :datetime         not null
#  is_approved     :boolean          default(FALSE)
#  name            :string           not null
#  secret_key      :string
#  slug            :string
#  start_time      :datetime         not null
#  subject         :string           not null
#  timezone_offset :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null

require "nanoid"

class Booking < ApplicationRecord
  attr_accessor :date

  before_validation :set_default_timezone, if: -> { timezone_offset.blank? }

  validates :name, presence: true, length: { minimum: 3 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :date, presence: true, if: :new_record?
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :subject, presence: true, length: { minimum: 3 }
  validates :timezone_offset, presence: true

  validate :valid_date_range
  validate :valid_time_range
  validate :no_overlap_bookings
  validate :udi_itb_special_validations

  before_save :generate_key
  before_save :convert_times_to_utc
  before_save :auto_approve_special_bookings

  # Google Calendar sync callbacks
  after_commit :sync_with_google_calendar, on: [:create, :update], if: :should_sync_with_google?
  after_commit :remove_from_google_calendar, on: :destroy, if: :google_calendar_event_id?

  # Encrypt the name, email, subject, description and secret_key field before saving to the database using ActiveRecord's encrypts method
  encrypts :name, :email, :subject, :description, :secret_key

  # Check if this is a special UDI x ITB booking
  def special_booking?
    subject.include?("[UDIxITB]")
  end

  # Define UDI x ITB time slots for current week
  UDI_ITB_TIME_SLOTS = {
    # Thursday slots (23 total)
    thursday: [
      # Morning Session (08:00-12:00) - 7 slots
      { start: "08:00", end: "08:30", label: "08:00-08:30", session: "morning" },
      { start: "08:35", end: "09:05", label: "08:35-09:05", session: "morning" },
      { start: "09:10", end: "09:40", label: "09:10-09:40", session: "morning" },
      { start: "09:45", end: "10:15", label: "09:45-10:15", session: "morning" },
      { start: "10:20", end: "10:50", label: "10:20-10:50", session: "morning" },
      { start: "10:55", end: "11:25", label: "10:55-11:25", session: "morning" },
      { start: "11:30", end: "12:00", label: "11:30-12:00", session: "morning" },
      
      # Afternoon Session (13:00-17:30) - 8 slots
      { start: "13:00", end: "13:30", label: "13:00-13:30", session: "afternoon" },
      { start: "13:35", end: "14:05", label: "13:35-14:05", session: "afternoon" },
      { start: "14:10", end: "14:40", label: "14:10-14:40", session: "afternoon" },
      { start: "14:45", end: "15:15", label: "14:45-15:15", session: "afternoon" },
      { start: "15:20", end: "15:50", label: "15:20-15:50", session: "afternoon" },
      { start: "15:55", end: "16:25", label: "15:55-16:25", session: "afternoon" },
      { start: "16:30", end: "17:00", label: "16:30-17:00", session: "afternoon" },
      { start: "17:05", end: "17:35", label: "17:05-17:35", session: "afternoon" },
      
      # Evening Session (19:00-22:00) - 5 slots
      { start: "19:00", end: "19:30", label: "19:00-19:30", session: "evening" },
      { start: "19:35", end: "20:05", label: "19:35-20:05", session: "evening" },
      { start: "20:10", end: "20:40", label: "20:10-20:40", session: "evening" },
      { start: "20:45", end: "21:15", label: "20:45-21:15", session: "evening" },
      { start: "21:20", end: "21:50", label: "21:20-21:50", session: "evening" }
    ],
    
    # Friday slots (21 total)
    friday: [
      # Morning Session (08:00-11:00) - 5 slots
      { start: "08:00", end: "08:30", label: "08:00-08:30", session: "morning" },
      { start: "08:35", end: "09:05", label: "08:35-09:05", session: "morning" },
      { start: "09:10", end: "09:40", label: "09:10-09:40", session: "morning" },
      { start: "09:45", end: "10:15", label: "09:45-10:15", session: "morning" },
      { start: "10:20", end: "10:50", label: "10:20-10:50", session: "morning" },
      
      # Afternoon Session (13:00-17:30) - 8 slots
      { start: "13:00", end: "13:30", label: "13:00-13:30", session: "afternoon" },
      { start: "13:35", end: "14:05", label: "13:35-14:05", session: "afternoon" },
      { start: "14:10", end: "14:40", label: "14:10-14:40", session: "afternoon" },
      { start: "14:45", end: "15:15", label: "14:45-15:15", session: "afternoon" },
      { start: "15:20", end: "15:50", label: "15:20-15:50", session: "afternoon" },
      { start: "15:55", end: "16:25", label: "15:55-16:25", session: "afternoon" },
      { start: "16:30", end: "17:00", label: "16:30-17:00", session: "afternoon" },
      { start: "17:05", end: "17:35", label: "17:05-17:35", session: "afternoon" },
      
      # Evening Session (19:00-22:00) - 5 slots
      { start: "19:00", end: "19:30", label: "19:00-19:30", session: "evening" },
      { start: "19:35", end: "20:05", label: "19:35-20:05", session: "evening" },
      { start: "20:10", end: "20:40", label: "20:10-20:40", session: "evening" },
      { start: "20:45", end: "21:15", label: "20:45-21:15", session: "evening" },
      { start: "21:20", end: "21:50", label: "21:20-21:50", session: "evening" }
    ]
  }.freeze

  # Get disabled slots from cache/settings
  def self.get_disabled_udi_slots
    Rails.cache.fetch("disabled_udi_slots", expires_in: 1.hour) do
      {}
    end
  end

  # Set disabled slots
  def self.set_disabled_udi_slots(disabled_slots)
    Rails.cache.write("disabled_udi_slots", disabled_slots)
  end

  # Get all slots for a specific day
  def self.get_slots_for_day(day_name)
    case day_name.downcase
    when 'thursday', 'kamis', '4'
      UDI_ITB_TIME_SLOTS[:thursday]
    when 'friday', 'jumat', '5'  
      UDI_ITB_TIME_SLOTS[:friday]
    else
      []
    end
  end

  # Get available UDI slots for a specific date
  def self.available_udi_slots_for_date(date)
    return [] unless date.is_a?(Date)
    return [] unless [4, 5].include?(date.wday) # Only Thursday(4) and Friday(5)
    
    # Get slots for the day
    day_slots = get_slots_for_day(date.strftime('%A'))
    return [] if day_slots.empty?
    
    # Get disabled slots
    disabled_slots = get_disabled_udi_slots
    disabled_key = "#{date.strftime('%Y-%m-%d')}"
    disabled_for_date = disabled_slots[disabled_key] || []
    
    # Get already booked UDI slots
    booked_udi_slots = Booking.where(
      "DATE(start_time) = ? AND subject LIKE ? AND is_approved = ?",
      date,
      "%[UDIxITB]%", 
      true
    ).pluck(:start_time).map { |time| time.strftime("%H:%M") }
    
    # Get manual bookings (non-UDI) that might overlap with UDI slots
    manual_bookings = Booking.where(
      "DATE(start_time) = ? AND subject NOT LIKE ? AND is_approved = ?",
      date,
      "%[UDIxITB]%",
      true
    ).pluck(:start_time, :end_time)
    
    # Filter available slots
    day_slots.reject do |slot|
      slot_start = Time.parse(slot[:start])
      slot_end = Time.parse(slot[:end])
      
      # Check if slot is disabled by admin
      admin_disabled = disabled_for_date.include?(slot[:start])
      
      # Check if slot is already booked by UDI
      udi_booked = booked_udi_slots.include?(slot[:start])
      
      # Check if slot overlaps with manual bookings
      manual_overlap = manual_bookings.any? do |manual_start, manual_end|
        # Convert to same date for comparison
        manual_start_time = Time.parse(manual_start.strftime("%H:%M"))
        manual_end_time = Time.parse(manual_end.strftime("%H:%M"))
        
        # Check overlap: slot overlaps if it starts before manual ends and ends after manual starts
        slot_start < manual_end_time && slot_end > manual_start_time
      end
      
      admin_disabled || udi_booked || manual_overlap
    end
  end

  # Get slots grouped by session for better UI
  def self.get_grouped_slots_for_date(date)
    available_slots = available_udi_slots_for_date(date)
    
    grouped = {
      'morning' => [],
      'afternoon' => [], 
      'evening' => []
    }
    
    available_slots.each do |slot|
      grouped[slot[:session]] << slot
    end
    
    # Remove empty sessions and return with metadata
    grouped.reject { |session, slots| slots.empty? }.transform_values do |slots|
      {
        slots: slots,
        count: slots.length
      }
    end
  end

  # Get current week Thursday and Friday dates
  def self.current_week_udi_dates
    current_week_start = Date.current.beginning_of_week(:sunday)
    dates = []
    
    # Thursday
    thursday = current_week_start + 4.days
    dates << thursday if thursday >= Date.current
    
    # Friday  
    friday = current_week_start + 5.days
    dates << friday if friday >= Date.current
    
    dates
  end

  # Block manual UDI booking validation
  validate :block_manual_udi_booking

  # Calculate adaptive buffer time for UDI x ITB bookings
  def calculate_adaptive_buffer
    return 0 unless special_booking?
    
    # Count UDI x ITB sessions on the same day
    booking_date = start_time&.to_date || (date.present? ? Date.strptime(date, "%m/%d/%Y") : Date.current)
    same_day_sessions = Booking.where(
      "DATE(start_time) = ? AND subject LIKE ? AND is_approved = ?",
      booking_date,
      "%[UDIxITB]%",
      true
    ).where.not(id: id || 0).count
    
    # Include current booking if it's approved or being approved
    same_day_sessions += 1 if is_approved? || is_approved_changed?
    
    case same_day_sessions
    when 1..3
      5  # Full 5-minute buffer for light days
    when 4..6
      4  # 4-minute buffer for medium days  
    when 7..8
      3  # 3-minute buffer for busy days
    when 9..10
      2  # 2-minute minimal buffer for very busy days
    else
      1  # 1-minute minimal for extreme cases (11+ sessions)
    end
  end

  # Get formatted duration
  def duration_minutes
    return 0 unless start_time && end_time
    ((end_time - start_time) / 60).to_i
  end

  # Check if this booking was synced from Google Calendar
  def from_google_calendar?
    google_calendar_event_id.present?
  end

  # Mark booking as coming from UDI route
  def mark_from_udi_route!
    @from_udi_route = true
  end

  private

  def set_default_timezone
    self.timezone_offset = "UTC"
  end

  def valid_date_range
    return unless date.present? # Skip validation if date is not set (for existing records)
    return if from_google_calendar? # Skip date range validation for Google Calendar events
    
    parsed_date = Date.strptime(date, "%m/%d/%Y") rescue nil
    if parsed_date.nil?
      errors.add(:date, "is not a valid date format (must be mm/dd/yyyy)")
    else
      # Special validation for UDI x ITB bookings
      if special_booking?
        # Only allow October 2025
        unless parsed_date.year == 2025 && parsed_date.month == 10
          errors.add(:date, "must be in October 2025 for UDI x ITB bookings")
        end
        
        # For UDI x ITB bookings, only allow dates within the current Sunday week
        unless date_within_current_sunday_week?(parsed_date)
          errors.add(:date, "must be within the current Sunday week for UDI x ITB bookings")
        end
      else
        # Normal validation for regular bookings
        unless parsed_date.to_date.between?(Date.tomorrow, 2.months.from_now)
          errors.add(:date, "must be from tommorow up to 2 months ahead")
        end
      end
    end
  end

  def valid_time_range
    if start_time && end_time
      duration = (end_time - start_time) / 60
      
      # Special validation for UDI x ITB bookings
      if special_booking?
        if duration < 20
          errors.add(:end_time, "must be at least 20 minutes for UDI x ITB bookings")
        elsif duration > 30
          errors.add(:end_time, "cannot be more than 30 minutes for UDI x ITB bookings")
        end
      else
        # Normal validation for regular bookings
        if duration < 15
          errors.add(:end_time, "must be at least 15 minutes")
        elsif duration > 120 && !from_google_calendar?
          # Skip 2-hour limit for Google Calendar synced events
          errors.add(:end_time, "cannot be more than 2 hours")
        end
      end
    else
      errors.add(:start_time, "and end_time are required")
    end
  end

  def no_overlap_bookings
    # Calculate effective times considering adaptive buffer for UDI x ITB bookings
    buffer_minutes = calculate_adaptive_buffer
    effective_end_time = special_booking? ? end_time + buffer_minutes.minutes : end_time
    effective_start_time = start_time
    
    # Find overlapping bookings considering buffer times
    overlapping_bookings = Booking.where.not(id: id || 0)
      .where(is_approved: true)
      .select do |booking|
        other_buffer = booking.special_booking? ? booking.calculate_adaptive_buffer : 0
        other_effective_end = booking.special_booking? ? booking.end_time + other_buffer.minutes : booking.end_time
        other_effective_start = booking.start_time
        
        # Check if bookings overlap considering buffer time
        effective_start_time < other_effective_end && effective_end_time > other_effective_start
      end
    
    if overlapping_bookings.any?
      conflicting_booking = overlapping_bookings.first
      if conflicting_booking.special_booking?
        conflict_buffer = conflicting_booking.calculate_adaptive_buffer
        next_available = (conflicting_booking.end_time + conflict_buffer.minutes)
        errors.add(:base, "Booking conflicts with UDI x ITB session (includes #{conflict_buffer}-minute buffer). Next available time: #{next_available.strftime('%H:%M')}")
      else
        errors.add(:base, "Booking overlaps with an approved schedule")
      end
    end
  end

  def generate_key
    self.secret_key = SecureRandom.hex
    self.slug = Nanoid.generate(size: 8)
  end

  def convert_times_to_utc
    return unless date.present? && start_time.present? && end_time.present?
    
    timezone = ActiveSupport::TimeZone[timezone_offset]
    self.start_time = timezone.parse("#{date} #{start_time}").utc
    self.end_time = timezone.parse("#{date} #{end_time}").utc
  end

  def auto_approve_special_bookings
    if subject.include?("[UDIxITB]")
      self.is_approved = true
    end
  end

  def udi_itb_special_validations
    return unless special_booking?
    return unless date.present?
    return if from_google_calendar? # Skip for Google Calendar events
    
    parsed_date = Date.strptime(date, "%m/%d/%Y") rescue nil
    return unless parsed_date
    
    # Validate day of week (only Thursday and Friday allowed)
    day_of_week = parsed_date.wday
    unless [4, 5].include?(day_of_week) # 4 = Thursday, 5 = Friday
      errors.add(:date, "must be on Thursday or Friday for UDI x ITB bookings")
    end
  end

  # Helper method to check if date is within current Sunday week
  def date_within_current_sunday_week?(date)
    # Get current date in user's timezone
    user_timezone = ActiveSupport::TimeZone[timezone_offset] || Time.zone
    current_date = Time.current.in_time_zone(user_timezone).to_date
    
    # Find the current Sunday (start of week)
    current_sunday = current_date.beginning_of_week(:sunday)
    
    # Find the next Sunday (end of current week)
    next_sunday = current_sunday + 1.week
    
    # Check if the given date is within current Sunday week
    date.between?(current_sunday, next_sunday - 1.day)
  end

  def should_sync_with_google?
    # Only sync approved bookings to Google Calendar
    # Skip if it already came from Google Calendar (to avoid infinite loops)
    is_approved? && is_approved_changed? && google_calendar_event_id.blank?
  end

  def sync_with_google_calendar
    return unless is_approved?
    return if google_calendar_event_id.present? # Skip if already synced or came from Google
    
    Rails.logger.info "Syncing booking #{id} to Google Calendar"
    SyncGoogleCalendarJob.perform_later(self)
  end

  def schedule_google_calendar_removal
    return unless google_calendar_event_id.present?
    
    RemoveGoogleCalendarEventJob.perform_later(google_calendar_event_id)
  end

  private

  def block_manual_udi_booking
    # Only block if this is NOT from the special UDI booking route
    return if defined?(@from_udi_route) && @from_udi_route
    return unless special_booking?
    
    errors.add(:subject, "UDI x ITB bookings must be made through the special booking page. Please contact admin for the correct link.")
  end
end
