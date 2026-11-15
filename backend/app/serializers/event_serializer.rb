class EventSerializer
  def initialize(event)
    @event = event
  end

  # Fields shown in the events list.
  def as_json(*)
    {
      id: @event.id,
      name: @event.name,
      status: @event.status,
      source: @event.source,
      url: @event.url,
      language: @event.language,
      starts_at: @event.starts_at.iso8601,
      ends_at: @event.ends_at.iso8601,
      submissions_starts_at: @event.submissions_starts_at&.iso8601,
      submissions_ends_at: @event.submissions_ends_at&.iso8601,
      onsite: @event.onsite,
      location: @event.location,
      country: @event.country,
      twitch_url: @event.twitch_url,
      discord_url: @event.discord_url,
      youtube_url: @event.youtube_url,
      has_schedule: @event.schedule.present?
    }
  end

  # List fields plus the event page content.
  def as_detail_json
    as_json.merge(description: @event.description, schedule: @event.schedule)
  end
end
