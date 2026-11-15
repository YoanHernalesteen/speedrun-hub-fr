require "rails_helper"

RSpec.describe EventPolicy do
  let(:event) { build(:event) }

  context "without a signed-in user" do
    subject(:policy) { described_class.new(nil, event) }

    it "allows listing events" do
      expect(policy.index?).to be(true)
    end

    it "allows showing an event" do
      expect(policy.show?).to be(true)
    end

    it "does not allow changing events" do
      expect([ policy.create?, policy.update?, policy.destroy? ]).to all(be(false))
    end
  end

  describe "Scope" do
    it "includes every event" do
      events = create_list(:event, 2)

      expect(described_class::Scope.new(nil, Event).resolve).to match_array(events)
    end
  end
end
