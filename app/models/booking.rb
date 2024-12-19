# == Schema Information
#
# Table name: bookings
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
  validates :date, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :subject, presence: true, length: { minimum: 3 }
  validates :timezone_offset, presence: true

  validate :valid_date_range
  validate :valid_time_range
  validate :no_overlap_bookings

  before_save :generate_key
  before_save :convert_times_to_utc

  # Encrypt the name, email, subject, description and secret_key field before saving to the database using ActiveRecord's encrypts method
  encrypts :name, :email, :subject, :description, :secret_key

  private

  def set_default_timezone
    self.timezone_offset = "UTC"
  end

  def valid_date_range
    parsed_date = Date.strptime(date, "%m/%d/%Y") rescue nil
    if parsed_date.nil?
      errors.add(:date, "is not a valid date format (must be mm/dd/yyyy)")
    else
      unless parsed_date.to_date.between?(Date.tomorrow, 2.months.from_now)
        errors.add(:date, "must be from tommorow up to 2 months ahead")
      end
    end
  end

  def valid_time_range
    if start_time && end_time
      duration = (end_time - start_time) / 60
      if duration < 15
        errors.add(:end_time, "must be at least 15 minutes")
      elsif duration > 120
        errors.add(:end_time, "cannot be more than 2 hours")
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
    timezone = ActiveSupport::TimeZone[timezone_offset]
    self.start_time = timezone.parse("#{date} #{start_time}").utc
    self.end_time = timezone.parse("#{date} #{end_time}").utc
  end
end
