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
#  meeting_link             :string
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
  def self.get_slots_for_day(day_name_or_number)
    # Convert day name/number to day_of_week (0-6)
    day_of_week = case day_name_or_number.to_s.downcase
    when 'sunday', 'minggu', '0'
      0
    when 'monday', 'senin', '1'
      1
    when 'tuesday', 'selasa', '2'
      2
    when 'wednesday', 'rabu', '3'
      3
    when 'thursday', 'kamis', '4'
      4
    when 'friday', 'jumat', '5'
      5
    when 'saturday', 'sabtu', '6'
      6
    else
      return []
    end

    UdiConfiguration.generate_time_slots_for_day(day_of_week)
  end

  # Get available UDI slots for a specific date
  def self.available_udi_slots_for_date(date)
    return [] unless date.is_a?(Date)

    # Check if this day is enabled in configuration
    # wday: 0=Sunday, 1=Monday, ..., 6=Saturday
    # UdiConfiguration now uses: 0=Sunday, 1=Monday, ..., 6=Saturday
    day_of_week = date.wday # Use directly: 0-6
    return [] unless UdiConfiguration.enabled_days.include?(day_of_week)

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
      # Determine session based on time
      hour = slot[:start].split(':')[0].to_i
      session = if hour < 12
                  'morning'
                elsif hour < 17
                  'afternoon'
                else
                  'evening'
                end

      grouped[session] << slot
    end

    # Remove empty sessions and return with metadata
    grouped.reject { |session, slots| slots.empty? }.transform_values do |slots|
      {
        slots: slots,
        count: slots.length
      }
    end
  end

  # Get current week UDI dates based on enabled days in configuration
  def self.current_week_udi_dates
    current_week_start = Date.current.beginning_of_week(:sunday)
    dates = []

    enabled_days = UdiConfiguration.enabled_days

    # Generate dates for each enabled day
    enabled_days.each do |day_of_week|
      # day_of_week: 0=Sunday, 1=Monday, ..., 6=Saturday
      date = current_week_start + day_of_week.days
      dates << date if date >= Date.current
    end

    dates.sort
  end

  # Block manual UDI booking validation
  validate :block_manual_udi_booking

  # Calculate adaptive buffer time for UDI x ITB bookings
  def calculate_adaptive_buffer
    return 0 # No buffer needed with structured time slots
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

  def parse_date_attribute(date_str)
    return nil unless date_str.present?

    # Try YYYY-MM-DD format first (new format)
    begin
      return Date.strptime(date_str, "%Y-%m-%d")
    rescue ArgumentError
      # Fall back to MM/DD/YYYY format (legacy format)
      begin
        return Date.strptime(date_str, "%m/%d/%Y")
      rescue ArgumentError
        return nil
      end
    end
  end

  def set_default_timezone
    self.timezone_offset = "UTC"
  end

  def valid_date_range
    return unless date.present? # Skip validation if date is not set (for existing records)
    return if from_google_calendar? # Skip date range validation for Google Calendar events

    parsed_date = parse_date_attribute(date)
    if parsed_date.nil?
      errors.add(:date, "is not a valid date format")
    else
      # Special validation for UDI x ITB bookings
      if special_booking?
        # Allow October–December 2025 (inclusive)
        allowed_start = Date.new(2025, 10, 1)
        allowed_end   = Date.new(2025, 12, 31)
        unless parsed_date.between?(allowed_start, allowed_end)
          errors.add(:date, "must be between October–December 2025 for UDI x ITB bookings")
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
    # Skip overlap validation for UDI bookings since we use structured time slots
    return if special_booking?

    # For non-UDI bookings, ensure we have proper datetime objects for comparison
    return unless date.present? && start_time.present? && end_time.present?

    # Convert times to proper datetime objects if they're still strings
    if start_time.is_a?(String) || end_time.is_a?(String)
      timezone = ActiveSupport::TimeZone[timezone_offset]
      parsed_date = parse_date_attribute(date)
      return unless parsed_date

      date_for_parsing = parsed_date.strftime("%Y-%m-%d")

      temp_start_time = start_time.is_a?(String) ? timezone.parse("#{date_for_parsing} #{start_time}").utc : start_time
      temp_end_time = end_time.is_a?(String) ? timezone.parse("#{date_for_parsing} #{end_time}").utc : end_time
    else
      temp_start_time = start_time
      temp_end_time = end_time
    end

    # Find overlapping bookings (simple overlap check for non-UDI bookings)
    overlapping_bookings = Booking.where.not(id: id || 0)
      .where(is_approved: true)
      .select do |booking|
        # Simple overlap check: bookings overlap if one starts before the other ends
        temp_start_time < booking.end_time && temp_end_time > booking.start_time
      end

    if overlapping_bookings.any?
      errors.add(:base, "Booking overlaps with an approved schedule")
    end
  end

  def generate_key
    self.secret_key = SecureRandom.hex
    self.slug = Nanoid.generate(size: 8)
  end

  def convert_times_to_utc
    return unless date.present? && start_time.present? && end_time.present?

    timezone = ActiveSupport::TimeZone[timezone_offset]

    # Parse date with explicit format to avoid ambiguity
    parsed_date = parse_date_attribute(date)
    return unless parsed_date

    # Format as YYYY-MM-DD for consistent parsing
    date_for_parsing = parsed_date.strftime("%Y-%m-%d")

    self.start_time = timezone.parse("#{date_for_parsing} #{start_time}").utc
    self.end_time = timezone.parse("#{date_for_parsing} #{end_time}").utc
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

    parsed_date = parse_date_attribute(date)
    return unless parsed_date

    # Validate day of week based on enabled configurations
    # wday: 0=Sunday, 1=Monday, ..., 6=Saturday
    # UdiConfiguration now uses: 0=Sunday, 1=Monday, ..., 6=Saturday
    day_of_week = parsed_date.wday # Use directly: 0-6
    enabled_days = UdiConfiguration.enabled_days

    unless enabled_days.include?(day_of_week)
      enabled_day_names = enabled_days.map { |d| UdiConfiguration::DAYS[d][:name_id] }.join(', ')
      errors.add(:date, "harus pada hari #{enabled_day_names} untuk booking UDI x ITB")
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
