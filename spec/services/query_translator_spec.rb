require "rails_helper"

RSpec.describe QueryTranslator do
  describe "valid queries" do
    it "filters by a whitelisted field and operator" do
      matching = create(:exoplanet, disc_year: 2018)
      create(:exoplanet, disc_year: 2005)

      relation = described_class.new(
        "model" => "Exoplanet",
        "filters" => [ { "field" => "disc_year", "operator" => ">", "value" => 2010 } ]
      ).translate

      expect(relation.to_a).to eq([ matching ])
    end

    it "applies sort and limit" do
      create(:exoplanet, pl_name: "B", disc_year: 2010)
      create(:exoplanet, pl_name: "A", disc_year: 2020)

      relation = described_class.new(
        "model" => "Exoplanet",
        "filters" => [],
        "sort" => { "field" => "disc_year", "direction" => "desc" },
        "limit" => 1
      ).translate

      expect(relation.map(&:pl_name)).to eq([ "A" ])
    end

    it "applies group_by" do
      create(:exoplanet, hostname: nil, discoverymethod: "Transit")
      create(:exoplanet, hostname: nil, discoverymethod: "Transit")
      create(:exoplanet, hostname: nil, discoverymethod: "Radial Velocity")

      translator = described_class.new(
        "model" => "Exoplanet",
        "filters" => [],
        "aggregate" => { "function" => "count", "field" => nil },
        "group_by" => "discoverymethod"
      )
      relation = translator.translate

      expect(relation.count).to eq({ "Transit" => 2, "Radial Velocity" => 1 })
    end

    it "exposes the validated aggregate for the caller to execute" do
      translator = described_class.new(
        "model" => "Exoplanet",
        "filters" => [],
        "aggregate" => { "function" => "avg", "field" => "pl_rade" }
      )

      expect(translator.aggregate).to eq({ "function" => "avg", "field" => "pl_rade" })
    end

    it "works with StellarHost too" do
      create(:stellar_host, st_spectype: "G2 V")

      relation = described_class.new(
        "model" => "StellarHost",
        "filters" => [ { "field" => "st_spectype", "operator" => "=", "value" => "G2 V" } ]
      ).translate

      expect(relation.count).to eq(1)
    end
  end

  describe "invalid queries" do
    it "rejects an unknown model" do
      expect {
        described_class.new("model" => "User", "filters" => []).translate
      }.to raise_error(QueryTranslator::InvalidQueryError, /Unknown model/)
    end

    it "rejects a field that isn't a whitelisted column" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [ { "field" => "id", "operator" => "=", "value" => 1 } ]
        ).translate
      }.to raise_error(QueryTranslator::InvalidQueryError, /not whitelisted/)
    end

    it "rejects the foreign key field used by the association" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [ { "field" => "hostname", "operator" => "=", "value" => "TRAPPIST-1" } ]
        ).translate
      }.to raise_error(QueryTranslator::InvalidQueryError, /not whitelisted/)
    end

    it "rejects an operator outside the whitelist" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [ { "field" => "disc_year", "operator" => "; DROP TABLE exoplanets;--", "value" => 1 } ]
        ).translate
      }.to raise_error(QueryTranslator::InvalidQueryError, /Operator not whitelisted/)
    end

    it "rejects an aggregate function outside the whitelist" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [],
          "aggregate" => { "function" => "stddev", "field" => "pl_rade" }
        )
      }.to raise_error(QueryTranslator::InvalidQueryError, /Aggregate function not whitelisted/)
    end

    it "rejects a non-count aggregate missing a field" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [],
          "aggregate" => { "function" => "sum", "field" => nil }
        )
      }.to raise_error(QueryTranslator::InvalidQueryError, /requires a field/)
    end

    it "rejects a group_by field outside the whitelist" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [],
          "group_by" => "id"
        )
      }.to raise_error(QueryTranslator::InvalidQueryError, /not whitelisted/)
    end

    it "rejects a sort direction outside the whitelist" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [],
          "sort" => { "field" => "disc_year", "direction" => "sideways" }
        ).translate
      }.to raise_error(QueryTranslator::InvalidQueryError, /Sort direction not whitelisted/)
    end

    it "rejects a non-integer limit" do
      expect {
        described_class.new(
          "model" => "Exoplanet",
          "filters" => [],
          "limit" => "10; DROP TABLE exoplanets;"
        ).translate
      }.to raise_error(QueryTranslator::InvalidQueryError, /Limit must be an integer/)
    end
  end
end
