# This valid booking factory need to be update every time the test is run
# Reason: The valid date only 2 months ahead from the current date
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
