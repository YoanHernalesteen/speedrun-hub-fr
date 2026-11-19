require "net/http"

module Events
  module Sources
    # Fetches French-speaking marathons from the public Oengus API
    # (https://docs.oengus.io/api/contents) and maps them to Event attributes.
    class Oengus
      class Error < StandardError; end

      SOURCE = "oengus"
      API_URL = "https://oengus.io/api"
      SITE_URL = "https://oengus.io"
      USER_AGENT = "SpeedrunHubFR"
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 15

      HANDLE = /\A[\w-]{1,100}\z/
      SOCIALS = {
        twitch: { base: "https://www.twitch.tv/", hosts: %w[twitch.tv www.twitch.tv] },
        discord: { base: "https://discord.gg/", hosts: %w[discord.gg discord.com www.discord.com] },
        youtube: { base: "https://www.youtube.com/", hosts: %w[youtube.com www.youtube.com youtu.be] }
      }.freeze

      def name
        SOURCE
      end

      def fetch(from:, to:)
        french_marathon_ids(from, to).filter_map do |id|
          details = get_json("/v1/marathons/#{id}")
          next if details["isPrivate"]

          to_attributes(details, schedule_for(id))
        end
      end

      private

      def french_marathon_ids(from, to)
        marathons = get_json("/v1/marathons/forDates",
          start: from.utc.iso8601, end: to.utc.iso8601, zoneId: "UTC")

        marathons
          .select { |marathon| french?(marathon["language"]) && !marathon["private"] }
          .map { |marathon| marathon["id"] }
      end

      def french?(language)
        language.to_s.downcase.match?(/\Afr(-|\z)/)
      end

      def to_attributes(details, schedule)
        {
          source: SOURCE,
          external_id: details["id"],
          name: details["name"],
          description: details["description"],
          url: "#{SITE_URL}/marathon/#{details["id"]}",
          language: details["language"],
          starts_at: parse_time(details["startDate"]),
          ends_at: parse_time(details["endDate"]),
          submissions_starts_at: parse_time(details["submissionsStartDate"]),
          submissions_ends_at: parse_time(details["submissionsEndDate"]),
          submissions_open: details["submitsOpen"] == true,
          onsite: details["onsite"] == true,
          location: details["location"].presence,
          country: details["country"].presence,
          twitch_url: social_url(details["twitch"], **SOCIALS[:twitch]),
          discord_url: social_url(details["discord"], **SOCIALS[:discord]),
          youtube_url: social_url(details["youtube"], **SOCIALS[:youtube]),
          schedule: schedule
        }
      end

      # Returns the lines of the first published schedule, or nil when none is
      # public yet (Oengus answers 401 for unpublished schedules).
      def schedule_for(id)
        schedules = get_json("/v2/marathons/#{id}/schedules", allow_missing: true)
        published = schedules&.fetch("data", [])&.find { |schedule| schedule["published"] }
        return if published.nil?

        lines = get_json("/v2/marathons/#{id}/schedules/for-slug/#{published["slug"]}",
          allow_missing: true, withCustomData: false)&.fetch("lines", [])
        lines.presence&.map { |line| schedule_line(line) }
      end

      # Keeps only what the app displays: no runner profile or linked accounts.
      def schedule_line(line)
        {
          "date" => line["date"],
          "game" => line["game"],
          "category" => line["category"],
          "console" => line["console"],
          "estimate" => line["estimate"],
          "runners" => Array(line["runners"]).filter_map { |runner| runner_name(runner) },
          "setup_block" => line["setupBlock"] == true
        }
      end

      def runner_name(runner)
        runner["runnerName"].presence || runner.dig("profile", "displayName").presence
      end

      # Accepts a bare handle/invite code, a YouTube "@handle", or an https URL
      # on the expected site. Anything else is dropped.
      def social_url(value, base:, hosts:)
        value = value.to_s.strip
        return if value.empty?

        if value.delete_prefix("@").match?(HANDLE)
          "#{base}#{value}"
        else
          uri = URI.parse(value)
          value if uri.is_a?(URI::HTTPS) && hosts.include?(uri.host)
        end
      rescue URI::InvalidURIError
        nil
      end

      def parse_time(value)
        Time.iso8601(value) if value.present?
      end

      def get_json(path, allow_missing: false, **params)
        uri = URI("#{API_URL}#{path}")
        uri.query = URI.encode_www_form(params) if params.any?

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
          open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
          http.get(uri.request_uri, "Accept" => "application/json", "User-Agent" => USER_AGENT)
        end

        case response
        when Net::HTTPSuccess then JSON.parse(response.body)
        when Net::HTTPUnauthorized, Net::HTTPNotFound
          raise Error, "Oengus returned #{response.code} for #{path}" unless allow_missing
        else
          raise Error, "Oengus returned #{response.code} for #{path}"
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Net::HTTPBadResponse, SocketError, SystemCallError, IOError,
             OpenSSL::SSL::SSLError => e
        raise Error, "Oengus request failed for #{path}: #{e.class}"
      rescue JSON::ParserError
        raise Error, "Oengus returned invalid JSON for #{path}"
      end
    end
  end
end
