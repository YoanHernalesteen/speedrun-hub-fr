require "rails_helper"
require "fugit"

RSpec.describe "config/recurring.yml" do
  let(:config) { YAML.load_file(Rails.root.join("config/recurring.yml")) }

  describe "Oengus events import" do
    let(:task) { config.dig("production", "import_oengus_events") }

    it "runs ImportOengusEventsJob" do
      expect(task).to include("class" => "ImportOengusEventsJob")
    end

    it "runs once a day at 6:00 Paris time" do
      schedule = Fugit.parse(task&.fetch("schedule", nil).to_s)

      # 6:00 in Paris is 5:00 UTC in winter.
      expect(schedule&.next_time(Time.utc(2026, 11, 15, 12))&.to_t&.utc).to eq(Time.utc(2026, 11, 16, 5))
    end
  end
end
