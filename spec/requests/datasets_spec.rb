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

    it "links to the random and extremes pages" do
      get dataset_path(dataset)

      expect(response.body).to include(random_dataset_path(dataset))
      expect(response.body).to include(extremes_dataset_path(dataset))
    end

    context "starfield visualization" do
      before do
        create(:dataset_column, dataset: dataset, name: "pl_rade", display_name: "Radius", data_type: "float", position: 2)
        create(:dataset_column, dataset: dataset, name: "sy_dist", display_name: "Distance", data_type: "float", position: 3)
        create(:dataset_column, dataset: dataset, name: "pl_eqt", display_name: "Temperature", data_type: "float", position: 4)
      end

      it "does not render the starfield canvas when required columns are absent" do
        columnless_dataset = create(:dataset)
        create(:dataset_row, dataset: columnless_dataset, data: { "pl_name" => "Kepler-442 b" })

        get dataset_path(columnless_dataset)

        expect(response.body).not_to include('data-controller="starfield"')
      end

      it "renders the starfield canvas with numeric points cast server-side" do
        create(:dataset_row, dataset: dataset, data: { "pl_name" => "Kepler-442 b", "pl_rade" => "1.34", "sy_dist" => "371.0", "pl_eqt" => "233.0" })

        get dataset_path(dataset)

        expect(response.body).to include('data-controller="starfield"')
        points = starfield_points(response.body)
        expect(points).to eq([ { "id" => points.first["id"], "pl_name" => "Kepler-442 b", "pl_rade" => 1.34, "sy_dist" => 371.0, "pl_eqt" => 233.0 } ])
      end

      it "excludes rows missing any of the three required fields" do
        create(:dataset_row, dataset: dataset, data: { "pl_name" => "Complete", "pl_rade" => "1.0", "sy_dist" => "10.0", "pl_eqt" => "300.0" })
        create(:dataset_row, dataset: dataset, data: { "pl_name" => "Missing Distance", "pl_rade" => "1.0", "pl_eqt" => "300.0" })

        get dataset_path(dataset)

        names = starfield_points(response.body).map { |point| point["pl_name"] }
        expect(names).to eq([ "Complete" ])
      end
    end

    def starfield_points(body)
      match = body.match(/data-starfield-points-value="([^"]*)"/)
      JSON.parse(CGI.unescapeHTML(match[1]))
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

  describe "GET /datasets/:id/random" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    before do
      create(:dataset_column, dataset: dataset, name: "pl_name", display_name: "Planet Name", data_type: "string", position: 0)
    end

    it "returns 404 for an unknown dataset" do
      get random_dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "renders a random row's values labeled with the column display name" do
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Kepler-442 b" })

      get random_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Kepler-442 b")
    end

    it "renders an empty state when the dataset has no rows" do
      get random_dataset_path(dataset)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no rows.")
    end
  end

  describe "GET /datasets/:id/extremes" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    before do
      create(:dataset_column, dataset: dataset, name: "pl_name", display_name: "Planet Name", data_type: "string", position: 0)
      create(:dataset_column, dataset: dataset, name: "pl_eqt", display_name: "Equilibrium Temp", data_type: "float", position: 1)
    end

    it "returns 404 for an unknown dataset" do
      get extremes_dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "ranks the hottest planets by pl_eqt descending" do
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Warm World", "pl_eqt" => "500.0" })
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Scorcher", "pl_eqt" => "2000.0" })

      get extremes_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Hottest")
      expect(response.body.index("Scorcher")).to be < response.body.index("Warm World")
    end

    it "ranks planets by closeness to Earth-size regardless of direction" do
      create(:dataset_column, dataset: dataset, name: "pl_rade", display_name: "Radius (Earth radii)", data_type: "float", position: 2)
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Just Right", "pl_rade" => "1.1" })
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Way Off", "pl_rade" => "9.0" })
      create(:dataset_row, dataset: dataset, data: { "pl_name" => "Slightly Small", "pl_rade" => "0.8" })

      get extremes_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Closest to Earth-size")
      body = response.body
      expect(body.index("Just Right")).to be < body.index("Slightly Small")
      expect(body.index("Slightly Small")).to be < body.index("Way Off")
    end

    it "renders an empty state for a leaderboard with no data" do
      get extremes_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("No data available.")
    end
  end
end
