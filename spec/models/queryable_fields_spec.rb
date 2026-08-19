require "rails_helper"

RSpec.describe QueryableFields do
  describe ".fields_for" do
    it "excludes id and timestamps" do
      expect(described_class.fields_for("Exoplanet")).not_to include("id", "created_at", "updated_at")
    end

    it "excludes the belongs_to foreign key on Exoplanet" do
      expect(described_class.fields_for("Exoplanet")).not_to include("hostname")
    end

    it "keeps hostname on StellarHost, where it isn't a foreign key" do
      expect(described_class.fields_for("StellarHost")).to include("hostname")
    end

    it "returns an empty array for an unknown model" do
      expect(described_class.fields_for("User")).to eq([])
    end
  end

  describe ".valid_operator?" do
    it "accepts whitelisted operators" do
      expect(described_class.valid_operator?("=")).to be true
      expect(described_class.valid_operator?(">=")).to be true
    end

    it "rejects anything else" do
      expect(described_class.valid_operator?("LIKE")).to be false
      expect(described_class.valid_operator?("; DROP TABLE exoplanets;--")).to be false
    end
  end

  describe ".valid_aggregate_function?" do
    it "accepts whitelisted functions" do
      expect(described_class.valid_aggregate_function?("avg")).to be true
    end

    it "rejects anything else" do
      expect(described_class.valid_aggregate_function?("stddev")).to be false
    end
  end
end
