class Event < ApplicationRecord
  HTTPS_URL = %r{\Ahttps://[^\s]+\z}

  validates :source, :external_id, :name, :url, :language, :starts_at, :ends_at, :synced_at, presence: true
  validates :external_id, uniqueness: { scope: :source }
  validates :url, :twitch_url, :discord_url, :youtube_url,
    format: { with: HTTPS_URL, message: "must be an https URL" }, allow_nil: true
  validate :ends_after_start

  # Live and future events (ended ones are kept but not listed).
  scope :upcoming, ->(now = Time.current) { where(ends_at: now..).order(:starts_at) }

  # Computed on read so it stays accurate between daily imports.
  def status(now = Time.current)
    if ends_at <= now
      "ended"
    elsif starts_at <= now
      "live"
    elsif schedule.present?
      "schedule_announced"
    elsif submissions_starts_at.nil? || submissions_ends_at.nil?
      "submissions_closed"
    elsif now < submissions_starts_at
      "submissions_upcoming"
    elsif now < submissions_ends_at && submissions_open
      "submissions_open"
    else
      "submissions_closed"
    end
  end

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after starts_at") if ends_at < starts_at
  end
end
