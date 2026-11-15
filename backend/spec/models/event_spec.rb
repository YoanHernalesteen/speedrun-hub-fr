require "rails_helper"

RSpec.describe Event, type: :model do
  let(:now) { Time.zone.parse("2026-11-15 12:00") }

  describe "validations" do
    it "is valid with the factory defaults" do
      expect(build(:event)).to be_valid
    end

    %i[source external_id name url language starts_at ends_at synced_at].each do |attribute|
      it "requires #{attribute}" do
        event = build(:event, attribute => nil)

        expect(event).not_to be_valid
        expect(event.errors[attribute]).to be_present
      end
    end

    it "requires a unique external_id within the same source" do
      create(:event, source: "oengus", external_id: "NDS3")

      duplicate = build(:event, source: "oengus", external_id: "NDS3")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to be_present
    end

    it "allows the same external_id for different sources" do
      create(:event, source: "oengus", external_id: "NDS3")

      expect(build(:event, source: "other", external_id: "NDS3")).to be_valid
    end

    it "requires ends_at to be after starts_at" do
      event = build(:event, starts_at: now, ends_at: now - 1.hour)

      expect(event).not_to be_valid
      expect(event.errors[:ends_at]).to be_present
    end

    %i[url twitch_url discord_url youtube_url].each do |attribute|
      it "rejects a non-https #{attribute}" do
        event = build(:event, attribute => "javascript:alert(1)")

        expect(event).not_to be_valid
        expect(event.errors[attribute]).to be_present
      end
    end

    it "accepts https social links" do
      event = build(:event,
        twitch_url: "https://www.twitch.tv/nitro_speedrun",
        discord_url: "https://discord.gg/tSVHSKsybG",
        youtube_url: "https://www.youtube.com/channel/UCW8jjfq3NrIBanEIWF2-ALw")

      expect(event).to be_valid
    end
  end

  describe ".upcoming" do
    it "returns live and future events ordered by start date, excluding ended ones" do
      later = create(:event, starts_at: now + 10.days, ends_at: now + 11.days)
      live = create(:event, starts_at: now - 1.hour, ends_at: now + 1.hour)
      sooner = create(:event, starts_at: now + 2.days, ends_at: now + 3.days)
      create(:event, starts_at: now - 3.days, ends_at: now - 1.day)

      expect(described_class.upcoming(now)).to eq([ live, sooner, later ])
    end
  end

  describe "#status" do
    let(:event) do
      build(:event,
        starts_at: now + 30.days,
        ends_at: now + 32.days,
        submissions_starts_at: now - 5.days,
        submissions_ends_at: now + 5.days,
        submissions_open: true)
    end

    it "is live while the event is running" do
      event.assign_attributes(starts_at: now - 1.hour, ends_at: now + 1.hour)

      expect(event.status(now)).to eq("live")
    end

    it "is ended once the event is over" do
      event.assign_attributes(starts_at: now - 2.days, ends_at: now - 1.day)

      expect(event.status(now)).to eq("ended")
    end

    it "is schedule_announced when a schedule has been published" do
      event.schedule = [ { "game" => "Pikmin 3 Deluxe" } ]

      expect(event.status(now)).to eq("schedule_announced")
    end

    it "prefers live over schedule_announced" do
      event.assign_attributes(starts_at: now - 1.hour, ends_at: now + 1.hour,
        schedule: [ { "game" => "Pikmin 3 Deluxe" } ])

      expect(event.status(now)).to eq("live")
    end

    it "is submissions_open during the submission period" do
      expect(event.status(now)).to eq("submissions_open")
    end

    it "is submissions_closed when the organizers closed submissions early" do
      event.submissions_open = false

      expect(event.status(now)).to eq("submissions_closed")
    end

    it "is submissions_upcoming before the submission period" do
      event.assign_attributes(submissions_starts_at: now + 1.day, submissions_ends_at: now + 10.days,
        submissions_open: false)

      expect(event.status(now)).to eq("submissions_upcoming")
    end

    it "is submissions_closed after the submission period" do
      event.assign_attributes(submissions_starts_at: now - 10.days, submissions_ends_at: now - 1.day)

      expect(event.status(now)).to eq("submissions_closed")
    end

    it "is submissions_closed when submission dates are missing" do
      event.assign_attributes(submissions_starts_at: nil, submissions_ends_at: nil)

      expect(event.status(now)).to eq("submissions_closed")
    end
  end
end
