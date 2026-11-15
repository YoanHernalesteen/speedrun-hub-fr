require "rails_helper"

RSpec.describe Events::Import do
  subject(:import) { described_class.new(source:) }

  let(:source) { instance_double(Events::Sources::Oengus, name: "oengus", fetch: fetched) }
  let(:from) { Time.current }
  let(:to) { 12.months.from_now }
  let(:fetched) { [ attributes_for_source("NDS3") ] }

  before { freeze_time }

  def attributes_for_source(external_id, **overrides)
    {
      source: "oengus",
      external_id:,
      name: "Marathon #{external_id}",
      description: "Bienvenue",
      url: "https://oengus.io/marathon/#{external_id}",
      language: "fr",
      starts_at: 10.days.from_now,
      ends_at: 12.days.from_now,
      submissions_starts_at: nil,
      submissions_ends_at: nil,
      submissions_open: false,
      onsite: false,
      location: nil,
      country: nil,
      twitch_url: nil,
      discord_url: nil,
      youtube_url: nil,
      schedule: nil
    }.merge(overrides)
  end

  it "fetches the source for the given window" do
    import.call(from:, to:)

    expect(source).to have_received(:fetch).with(from:, to:)
  end

  it "creates new events and records the sync time" do
    expect { import.call(from:, to:) }.to change(Event, :count).by(1)

    event = Event.find_by!(source: "oengus", external_id: "NDS3")
    expect(event).to have_attributes(name: "Marathon NDS3", synced_at: Time.current)
  end

  it "updates an existing event instead of duplicating it" do
    event = create(:event, source: "oengus", external_id: "NDS3", name: "Old name", synced_at: 2.days.ago)

    expect { import.call(from:, to:) }.not_to change(Event, :count)
    expect(event.reload).to have_attributes(name: "Marathon NDS3", synced_at: Time.current)
  end

  it "deletes not yet ended events of the source that are no longer returned" do
    create(:event, source: "oengus", external_id: "gone", starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    create(:event, source: "oengus", external_id: "live-gone", starts_at: 1.hour.ago, ends_at: 1.hour.from_now)

    import.call(from:, to:)

    expect(Event.pluck(:external_id)).to contain_exactly("NDS3")
  end

  it "keeps ended events even when they are no longer returned" do
    create(:event, source: "oengus", external_id: "past", starts_at: 3.days.ago, ends_at: 2.days.ago)

    import.call(from:, to:)

    expect(Event.pluck(:external_id)).to contain_exactly("NDS3", "past")
  end

  it "keeps events from other sources" do
    create(:event, source: "other", external_id: "elsewhere")

    import.call(from:, to:)

    expect(Event.pluck(:external_id)).to contain_exactly("NDS3", "elsewhere")
  end

  context "when an event from the source is invalid" do
    let(:fetched) do
      [
        attributes_for_source("broken", ends_at: 1.day.ago, starts_at: 1.day.from_now),
        attributes_for_source("NDS3")
      ]
    end

    it "skips it and still imports the others" do
      import.call(from:, to:)

      expect(Event.pluck(:external_id)).to contain_exactly("NDS3")
    end

    it "keeps the previously imported version instead of deleting it" do
      create(:event, source: "oengus", external_id: "broken", name: "Previous version", synced_at: 2.days.ago)

      import.call(from:, to:)

      expect(Event.pluck(:external_id)).to contain_exactly("broken", "NDS3")
      expect(Event.find_by(external_id: "broken")).to have_attributes(name: "Previous version")
    end
  end

  it "returns a summary of the changes" do
    create(:event, source: "oengus", external_id: "NDS3")
    create(:event, source: "oengus", external_id: "gone")
    allow(source).to receive(:fetch).and_return([
      attributes_for_source("NDS3"),
      attributes_for_source("new"),
      attributes_for_source("other-new"),
      attributes_for_source("broken", ends_at: 1.day.ago)
    ])

    expect(import.call(from:, to:)).to eq(created: 2, updated: 1, deleted: 1, skipped: 1)
  end

  it "changes nothing when the source fails" do
    create(:event, source: "oengus", external_id: "kept")
    allow(source).to receive(:fetch).and_raise(Events::Sources::Oengus::Error, "Oengus returned 500")

    expect { import.call(from:, to:) }.to raise_error(Events::Sources::Oengus::Error)
    expect(Event.pluck(:external_id)).to contain_exactly("kept")
  end
end
