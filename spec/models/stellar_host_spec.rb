require "rails_helper"

RSpec.describe StellarHost, type: :model do
  describe "#exoplanets" do
    it "returns exoplanets that share its hostname" do
      stellar_host = create(:stellar_host, hostname: "TRAPPIST-1")
      matching = create(:exoplanet, hostname: "TRAPPIST-1")
      create(:exoplanet, hostname: "Other Host")

      expect(stellar_host.exoplanets).to contain_exactly(matching)
    end
  end
end
