# This valid booking factory need to be update every time the test is run
# Reason: The valid date only 2 months ahead from the current date
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
FactoryBot.define do
  factory :booking do
    name { "John Doe" }
    email { "john@example.com" }
    date { "02/01/2025" }
    start_time { DateTime.new(2025, 2, 1, 11, 0) }
    end_time { DateTime.new(2025, 2, 1, 12, 0) }
    subject { "Meeting" }
    description { "Discuss project updates" }
  end
end
