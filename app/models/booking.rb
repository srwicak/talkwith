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

  # Get formatted duration
  def duration_minutes
    return 0 unless start_time && end_time
    ((end_time - start_time) / 60).to_i
  end

  # Check if this booking was synced from Google Calendar
  def from_google_calendar?
    google_calendar_event_id.present?
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
    overlapping_bookings = Booking.where.not(id: id)
      .where("start_time < ? AND end_time > ?", end_time, start_time)
      .where(is_approved: true)
    errors.add(:base, "Booking overlaps with an approved schedule") if overlapping_bookings.exists?
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

  def remove_from_google_calendar
    return unless google_calendar_event_id.present?
    
    RemoveGoogleCalendarEventJob.perform_later(google_calendar_event_id)
  end
end
