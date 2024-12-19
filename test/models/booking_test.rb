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
#
require "test_helper"

class BookingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
