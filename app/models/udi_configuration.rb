# == Schema Information
#
# Table name: udi_configurations
#
#  id            :integer          not null, primary key
#  buffer_time   :integer          default(5)
#  day_of_week   :integer          not null
#  enabled       :boolean          default(TRUE)
#  end_time      :string           not null
#  slot_duration :integer          default(30)
#  start_time    :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_udi_configurations_on_day_of_week  (day_of_week)
#  index_udi_configurations_on_enabled      (enabled)
#
class UdiConfiguration < ApplicationRecord
  # Validations
  validates :day_of_week, presence: true, inclusion: { in: 0..6 } # 0=Sunday to 6=Saturday
  validates :start_time, presence: true, format: { with: /\A([01]?[0-9]|2[0-3]):[0-5][0-9]\z/, message: "must be in HH:MM format" }
  validates :end_time, presence: true, format: { with: /\A([01]?[0-9]|2[0-3]):[0-5][0-9]\z/, message: "must be in HH:MM format" }
  validates :slot_duration, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 120 }
  validates :buffer_time, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 30 }

  validate :end_time_after_start_time

  # Constants
  DAYS = {
    0 => { name: 'Sunday', name_id: 'Minggu' },
    1 => { name: 'Monday', name_id: 'Senin' },
    2 => { name: 'Tuesday', name_id: 'Selasa' },
    3 => { name: 'Wednesday', name_id: 'Rabu' },
    4 => { name: 'Thursday', name_id: 'Kamis' },
    5 => { name: 'Friday', name_id: "Jum'at" },
    6 => { name: 'Saturday', name_id: 'Sabtu' }
  }.freeze

  # Class methods
  def self.enabled_days
    where(enabled: true).order(:day_of_week).pluck(:day_of_week).uniq
  end

  def self.for_day(day_of_week)
    where(day_of_week: day_of_week, enabled: true).first
  end

  def self.generate_time_slots_for_day(day_of_week)
    config = for_day(day_of_week)
    return [] unless config

    slots = []
    current_time = Time.parse(config.start_time)
    end_time = Time.parse(config.end_time)

    while current_time + config.slot_duration.minutes <= end_time
      slot_end = current_time + config.slot_duration.minutes

      slots << {
        start: current_time.strftime("%H:%M"),
        end: slot_end.strftime("%H:%M"),
        label: "#{current_time.strftime('%H:%M')}-#{slot_end.strftime('%H:%M')}",
        duration: config.slot_duration
      }

      # Add buffer time for next slot
      current_time = slot_end + config.buffer_time.minutes
    end

    slots
  end

  # Instance methods
  def day_name
    DAYS[day_of_week][:name]
  end

  def day_name_id
    DAYS[day_of_week][:name_id]
  end

  def total_slots
    return 0 unless start_time.present? && end_time.present?

    start = Time.parse(start_time)
    finish = Time.parse(end_time)
    duration_minutes = ((finish - start) / 60).to_i

    # Calculate number of slots: (total_time) / (slot_duration + buffer_time)
    (duration_minutes / (slot_duration + buffer_time)).floor
  end

  private

  def end_time_after_start_time
    return unless start_time.present? && end_time.present?

    start = Time.parse(start_time)
    finish = Time.parse(end_time)

    if finish <= start
      errors.add(:end_time, "must be after start time")
    end
  end
end
