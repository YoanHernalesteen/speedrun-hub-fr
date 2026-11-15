require "rails_helper"

RSpec.describe ImportOengusEventsJob do
  it "imports Oengus events for the next 12 months" do
    freeze_time
    import = instance_double(Events::Import, call: {})
    allow(Events::Import).to receive(:new).and_return(import)

    described_class.perform_now

    expect(Events::Import).to have_received(:new).with(source: an_instance_of(Events::Sources::Oengus))
    expect(import).to have_received(:call).with(from: Time.current, to: 12.months.from_now)
  end
end
