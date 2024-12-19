RSpec.describe Schedules::IcsGeneratorService do
  let(:appointment) { build(:booking, start_time: "2024-12-19 10:00:00", end_time: "2024-12-19 12:00:00", subject: "Meeting", description: "Discuss project") }

  it "generates valid ICS data" do
    ics_data = described_class.generate(appointment)
    expect(ics_data).to include("BEGIN:VEVENT", "SUMMARY:Meeting", "DESCRIPTION:Discuss project")
  end
end
