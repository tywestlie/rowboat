require "rails_helper"

RSpec.describe Dataset, type: :model do
  describe "validations" do
    it "requires a name" do
      dataset = build(:dataset, name: nil)

      expect(dataset).not_to be_valid
    end
  end

  describe "#safe_source_url" do
    it "returns http(s) urls unchanged" do
      dataset = build(:dataset, source_url: "https://example.com/data.csv")

      expect(dataset.safe_source_url).to eq("https://example.com/data.csv")
    end

    it "returns nil for non-http(s) schemes" do
      dataset = build(:dataset, source_url: "javascript:alert(1)")

      expect(dataset.safe_source_url).to be_nil
    end

    it "returns nil when blank" do
      dataset = build(:dataset, source_url: nil)

      expect(dataset.safe_source_url).to be_nil
    end
  end
end
