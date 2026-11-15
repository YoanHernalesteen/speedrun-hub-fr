require "rails_helper"

RSpec.describe "API events", type: :request do
  before { freeze_time }

  let(:schedule) do
    [ { "date" => "2026-11-27T17:00:00Z", "game" => "Pikmin 3 Deluxe", "category" => "Any%",
        "console" => "Switch", "estimate" => "PT39M", "runners" => [ "lemery" ], "setup_block" => false } ]
  end

  describe "GET /api/events" do
    it "lists live and upcoming events by start date, without ended ones" do
      later = create(:event, starts_at: 10.days.from_now, ends_at: 11.days.from_now)
      live = create(:event, starts_at: 1.hour.ago, ends_at: 1.hour.from_now)
      create(:event, starts_at: 3.days.ago, ends_at: 2.days.ago)

      get "/api/events"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["events"].pluck("id")).to eq([ live.id, later.id ])
    end

    it "returns the summary fields of each event" do
      event = create(:event,
        name: "Nitro Days for SPDA 2026",
        external_id: "NDS3",
        url: "https://oengus.io/marathon/NDS3",
        language: "fr",
        submissions_starts_at: 5.days.ago,
        submissions_ends_at: 5.days.from_now,
        submissions_open: true,
        onsite: true,
        location: "Lyon",
        country: "FR",
        twitch_url: "https://www.twitch.tv/nitro_speedrun",
        discord_url: "https://discord.gg/tSVHSKsybG",
        youtube_url: "https://www.youtube.com/@nitro",
        description: "Bienvenue",
        schedule:)

      get "/api/events"

      expect(response.parsed_body["events"].sole).to eq(
        "id" => event.id,
        "name" => "Nitro Days for SPDA 2026",
        "status" => "schedule_announced",
        "source" => "oengus",
        "url" => "https://oengus.io/marathon/NDS3",
        "language" => "fr",
        "starts_at" => event.starts_at.iso8601,
        "ends_at" => event.ends_at.iso8601,
        "submissions_starts_at" => event.submissions_starts_at.iso8601,
        "submissions_ends_at" => event.submissions_ends_at.iso8601,
        "onsite" => true,
        "location" => "Lyon",
        "country" => "FR",
        "twitch_url" => "https://www.twitch.tv/nitro_speedrun",
        "discord_url" => "https://discord.gg/tSVHSKsybG",
        "youtube_url" => "https://www.youtube.com/@nitro",
        "has_schedule" => true
      )
    end

    it "returns null for missing submission dates" do
      create(:event, submissions_starts_at: nil, submissions_ends_at: nil)

      get "/api/events"

      expect(response.parsed_body["events"].sole)
        .to include("submissions_starts_at" => nil, "submissions_ends_at" => nil, "has_schedule" => false)
    end
  end

  describe "GET /api/events/:id" do
    it "returns the event with its description and schedule" do
      event = create(:event, description: "# Bienvenue", schedule:)

      get "/api/events/#{event.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["event"]).to include(
        "id" => event.id,
        "status" => "schedule_announced",
        "description" => "# Bienvenue",
        "schedule" => schedule
      )
    end

    it "does not expose internal fields" do
      event = create(:event)

      get "/api/events/#{event.id}"

      keys = response.parsed_body["event"].keys
      expect(keys).to include("id", "name", "description")
      expect(keys).not_to include("external_id", "synced_at", "created_at", "updated_at")
    end

    it "responds with 404 and a JSON error for an unknown event" do
      get "/api/events/0"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq("error" => "not_found")
    end
  end
end
