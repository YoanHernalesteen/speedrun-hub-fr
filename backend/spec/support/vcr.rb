require "vcr"
require "webmock/rspec"

# Removes personal data (organizers, linked accounts, runner profiles) from
# recorded JSON: the app never uses it and it must not end up in the repository.
# Runner profiles only keep the display name.
scrub_personal_data = lambda do |data|
  case data
  when Hash
    data.except("creator", "moderators", "connections").to_h do |key, value|
      value = value.slice("displayName") if key == "profile" && value.is_a?(Hash)
      [ key, scrub_personal_data.call(value) ]
    end
  when Array then data.map { |value| scrub_personal_data.call(value) }
  else data
  end
end

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("spec/cassettes").to_s
  config.hook_into :webmock
  config.configure_rspec_metadata!
  # CI only replays cassettes; locally, a missing cassette is recorded once.
  config.default_cassette_options = { record: ENV["CI"] ? :none : :once }

  config.before_record do |interaction|
    data = JSON.parse(interaction.response.body)
    interaction.response.body = JSON.generate(scrub_personal_data.call(data))
  rescue JSON::ParserError
    # Not JSON: keep the body as is.
  end
end
