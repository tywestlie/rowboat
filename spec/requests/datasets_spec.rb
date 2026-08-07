require "rails_helper"

RSpec.describe "Datasets", type: :request do
  describe "GET /datasets" do
    it "renders successfully with no datasets" do
      get datasets_path
      expect(response).to have_http_status(:success)
    end

    it "lists datasets ordered by name with their row count" do
      create(:dataset, name: "Zeta Catalog", row_count: 3, imported_at: Time.current)
      create(:dataset, name: "Alpha Catalog", row_count: 7, imported_at: Time.current)

      get datasets_path

      expect(response).to have_http_status(:success)
      expect(response.body.index("Alpha Catalog")).to be < response.body.index("Zeta Catalog")
      expect(response.body).to include("7")
    end
  end

  describe "GET /datasets/:id" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    before do
      create(:dataset_column, dataset: dataset, name: "pl_name", display_name: "Planet Name", data_type: "string", position: 0)
      create(:dataset_column, dataset: dataset, name: "disc_year", display_name: "Discovery Year", data_type: "integer", position: 1)
    end

    it "returns 404 for an unknown dataset" do
      get dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "renders column headers and row values" do
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Kepler-442 b", "disc_year" => "2015" })

      get dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Discovery Year")
      expect(response.body).to include("Kepler-442 b")
    end

    it "renders an empty state when the dataset has no rows" do
      get dataset_path(dataset)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no rows.")
    end

    context "with more than 50 rows" do
      before do
        51.times { |i| create(:dataset_row, dataset: dataset, data: { "pl_name" => "Planet #{i}", "disc_year" => "2000" }) }
      end

      it "shows only the first 50 rows on page 1 and links to page 2" do
        get dataset_path(dataset)

        expect(response.body).to include("Planet 0")
        expect(response.body).not_to include("Planet 50")
        expect(response.body).to include("page=2")
      end

      it "shows the 51st row on page 2" do
        get dataset_path(dataset, page: 2)

        expect(response.body).to include("Planet 50")
      end
    end
  end
end
