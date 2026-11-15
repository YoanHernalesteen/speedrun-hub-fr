FactoryBot.define do
  factory :event do
    source { "oengus" }
    sequence(:external_id) { |n| "marathon#{n}" }
    name { "Speedrun Marathon" }
    url { "https://oengus.io/marathon/#{external_id}" }
    language { "fr" }
    starts_at { 30.days.from_now }
    ends_at { 32.days.from_now }
    synced_at { Time.current }
  end
end
