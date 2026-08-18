require "rails_helper"

RSpec.describe Exoplanet, type: :model do
  describe "#stellar_host" do
    it "resolves the stellar host by matching hostname" do
      stellar_host = create(:stellar_host, hostname: "TRAPPIST-1")
      exoplanet = create(:exoplanet, hostname: "TRAPPIST-1")

      expect(exoplanet.stellar_host).to eq(stellar_host)
    end

    it "is nil when no stellar host matches the hostname" do
      exoplanet = create(:exoplanet, hostname: "Unknown Host")

      expect(exoplanet.stellar_host).to be_nil
    end
  end
end
