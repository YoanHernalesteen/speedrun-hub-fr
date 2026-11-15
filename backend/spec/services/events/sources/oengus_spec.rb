require "rails_helper"

RSpec.describe Events::Sources::Oengus do
  subject(:source) { described_class.new }

  let(:api) { "https://oengus.io/api" }

  describe "#fetch", vcr: { cassette_name: "oengus/french_events" } do
    # Window containing two French marathons: NDS3 (published schedule)
    # and cst2026 (schedule not published yet).
    let(:events) do
      source.fetch(from: Time.utc(2026, 11, 20), to: Time.utc(2026, 12, 15))
    end
    let(:nds3) { events.find { |event| event[:external_id] == "NDS3" } }

    it "returns only French events" do
      expect(events.map { |event| event[:external_id] }).to contain_exactly("NDS3", "cst2026")
    end

    it "maps the marathon details" do
      expect(nds3).to include(
        source: "oengus",
        name: "Nitro Days for SPDA 2026",
        url: "https://oengus.io/marathon/NDS3",
        language: "fr",
        starts_at: Time.utc(2026, 11, 27, 17, 0),
        ends_at: Time.utc(2026, 11, 29, 21, 30),
        submissions_starts_at: Time.utc(2026, 9, 4, 18, 0),
        submissions_ends_at: Time.utc(2026, 9, 27, 21, 59),
        submissions_open: false,
        onsite: false,
        location: nil,
        country: nil,
        twitch_url: "https://www.twitch.tv/nitro_speedrun",
        discord_url: "https://discord.gg/tSVHSKsybG",
        youtube_url: "https://www.youtube.com/channel/UCW8jjfq3NrIBanEIWF2-ALw"
      )
      expect(nds3[:description]).to include("Nitro Days for SPDA 2026")
    end

    it "keeps only the useful fields of the published schedule" do
      expect(nds3[:schedule].first).to eq(
        "date" => "2026-11-27T17:00:00Z",
        "game" => "Pikmin 3 Deluxe",
        "category" => "Any%",
        "console" => "Switch",
        "estimate" => "PT39M",
        "runners" => [ "lemery" ],
        "setup_block" => false
      )
    end

    it "has no schedule when it is not published yet" do
      cst2026 = events.find { |event| event[:external_id] == "cst2026" }

      expect(cst2026[:schedule]).to be_nil
    end
  end

  describe "#fetch with stubbed responses" do
    let(:from) { Time.utc(2026, 11, 20) }
    let(:to) { Time.utc(2026, 12, 15) }
    let(:summary) { { "id" => "frmara", "language" => "fr-FR", "private" => false } }
    let(:details) do
      {
        "id" => "frmara",
        "name" => "Marathon FR",
        "description" => "Bienvenue",
        "language" => "fr-FR",
        "isPrivate" => false,
        "startDate" => "2026-12-01T18:00:00Z",
        "endDate" => "2026-12-02T18:00:00Z",
        "submissionsStartDate" => nil,
        "submissionsEndDate" => nil,
        "submitsOpen" => false,
        "onsite" => true,
        "location" => "Lyon",
        "country" => "FR",
        "twitch" => "javascript:alert(1)",
        "discord" => "https://evil.example/invite",
        "youtube" => "@speedrunfr"
      }
    end

    before do
      stub_request(:get, "#{api}/v1/marathons/forDates")
        .with(query: hash_including({}))
        .to_return_json(body: [ summary, { "id" => "enmara", "language" => "en", "private" => false } ])
      stub_request(:get, "#{api}/v1/marathons/frmara").to_return_json(body: details)
      stub_request(:get, "#{api}/v2/marathons/frmara/schedules").to_return(status: 401)
    end

    it "only requests details for French events" do
      source.fetch(from:, to:)

      expect(a_request(:get, "#{api}/v1/marathons/enmara")).not_to have_been_made
    end

    it "accepts regional French language codes and maps the location" do
      event = source.fetch(from:, to:).sole

      expect(event).to include(external_id: "frmara", language: "fr-FR", onsite: true,
        location: "Lyon", country: "FR")
    end

    it "drops social links that are not valid handles or https links to the expected site" do
      event = source.fetch(from:, to:).sole

      expect(event).to include(twitch_url: nil, discord_url: nil)
    end

    it "drops social links that are not https" do
      stub_request(:get, "#{api}/v1/marathons/frmara")
        .to_return_json(body: details.merge("twitch" => "http://www.twitch.tv/speedrunfr"))

      expect(source.fetch(from:, to:).sole[:twitch_url]).to be_nil
    end

    it "ignores events flagged as private in the marathon list" do
      stub_request(:get, "#{api}/v1/marathons/forDates")
        .with(query: hash_including({}))
        .to_return_json(body: [ summary.merge("private" => true) ])

      expect(source.fetch(from:, to:)).to be_empty
      expect(a_request(:get, "#{api}/v1/marathons/frmara")).not_to have_been_made
    end

    it "ignores schedules that are not published" do
      stub_request(:get, "#{api}/v2/marathons/frmara/schedules")
        .to_return_json(body: { "data" => [ { "slug" => "draft", "published" => false } ] })

      expect(source.fetch(from:, to:).sole[:schedule]).to be_nil
      expect(a_request(:get, %r{/schedules/for-slug/draft})).not_to have_been_made
    end

    it "turns a YouTube handle into a channel URL" do
      expect(source.fetch(from:, to:).sole[:youtube_url]).to eq("https://www.youtube.com/@speedrunfr")
    end

    it "skips events that became private" do
      stub_request(:get, "#{api}/v1/marathons/frmara").to_return_json(body: details.merge("isPrivate" => true))

      expect(source.fetch(from:, to:)).to be_empty
    end

    it "raises an error when Oengus answers with a server error" do
      stub_request(:get, "#{api}/v1/marathons/forDates").with(query: hash_including({})).to_return(status: 500)

      expect { source.fetch(from:, to:) }.to raise_error(Events::Sources::Oengus::Error, /500/)
    end

    it "raises an error when Oengus does not answer in time" do
      stub_request(:get, "#{api}/v1/marathons/forDates").with(query: hash_including({})).to_timeout

      expect { source.fetch(from:, to:) }.to raise_error(Events::Sources::Oengus::Error)
    end
  end
end
