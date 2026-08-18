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

    it "links to the systems page when the dataset is the Confirmed Exoplanets dataset" do
      dataset = create(:dataset, name: "Confirmed Exoplanets")

      get datasets_path

      expect(response.body).to include(systems_dataset_path(dataset))
    end

    it "does not link non-exoplanet datasets into the browsing pages" do
      dataset = create(:dataset, name: "Stellar Hosts")

      get datasets_path

      expect(response.body).to include("Stellar Hosts")
      expect(response.body).not_to include(systems_dataset_path(dataset))
      expect(response.body).not_to include(dataset_path(dataset))
    end
  end

  describe "GET /datasets/:id" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    it "returns 404 for an unknown dataset" do
      get dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "renders column headers and row values" do
      create(:exoplanet, pl_name: "Kepler-442 b", disc_year: 2015)

      get dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Discovery Year")
      expect(response.body).to include("Kepler-442 b")
    end

    it "renders an empty state when there are no exoplanets" do
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
      it "renders the starfield canvas with numeric points cast server-side" do
        exoplanet = create(:exoplanet, pl_name: "Kepler-442 b", pl_rade: 1.34, sy_dist: 371.0, pl_eqt: 233.0, pl_orbper: nil)

        get dataset_path(dataset)

        expect(response.body).to include('data-controller="starfield"')
        points = starfield_points(response.body)
        expect(points).to eq([ { "id" => exoplanet.id, "pl_name" => "Kepler-442 b", "pl_rade" => 1.34, "sy_dist" => 371.0, "pl_eqt" => 233.0 } ])
      end

      it "excludes rows missing any of the three required fields" do
        create(:exoplanet, pl_name: "Complete", pl_rade: 1.0, sy_dist: 10.0, pl_eqt: 300.0)
        create(:exoplanet, pl_name: "Missing Distance", pl_rade: 1.0, sy_dist: nil, pl_eqt: 300.0)

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
        51.times { |i| create(:exoplanet, pl_name: "Planet #{i}", disc_year: 2000, pl_rade: nil, sy_dist: nil, pl_eqt: nil) }
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

  describe "GET /datasets/:id host filtering" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets", row_count: 3) }

    before do
      create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", pl_rade: 1.12, sy_dist: 12.4, pl_eqt: 397.6, pl_orbper: 1.51)
      create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", pl_rade: 1.10, sy_dist: 12.4, pl_eqt: 339.7, pl_orbper: 2.42)
      create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World", pl_rade: 1.0, sy_dist: 50.0, pl_eqt: 255.0, pl_orbper: 365.0)
    end

    it "shows all rows when no host param is given, with sky mode starfield" do
      get dataset_path(dataset)

      expect(response.body).to include("TRAPPIST-1 b")
      expect(response.body).to include("Lone World b")
      expect(response.body).to include('data-starfield-mode-value="sky"')
    end

    it "filters rows and the starfield to the selected host" do
      get dataset_path(dataset), params: { hostname: "TRAPPIST-1" }

      expect(response.body).to include("Showing 2 planets around")
      expect(response.body).to include("TRAPPIST-1")
      expect(response.body).to include("TRAPPIST-1 b")
      expect(response.body).not_to include("Lone World b")
      expect(response.body).to include('data-starfield-mode-value="system"')
    end

    it "links back to the systems list from the filtered single-system view" do
      get dataset_path(dataset), params: { hostname: "TRAPPIST-1" }

      expect(response.body).to include("← All systems")
      expect(response.body).to include(systems_dataset_path(dataset))
    end

    it "shows an empty state for a host with no matches" do
      get dataset_path(dataset), params: { hostname: "Nonexistent" }

      expect(response.body).to include("Showing 0 planets around")
      expect(response.body).to include("This dataset has no rows.")
    end

    it "shows the associated stellar host's details when one exists" do
      create(:stellar_host, hostname: "TRAPPIST-1", st_spectype: "M8 V", st_teff: 2559.0)

      get dataset_path(dataset), params: { hostname: "TRAPPIST-1" }

      expect(response.body).to include("M8 V")
      expect(response.body).to include("2559")
    end
  end

  describe "GET /datasets/:id/systems" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    it "returns 404 for an unknown dataset" do
      get systems_dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "lists multi-planet systems sorted by planet count descending, excluding single-planet systems" do
      create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1")
      create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1")
      create(:exoplanet, pl_name: "Kepler-90 b", hostname: "Kepler-90")
      create(:exoplanet, pl_name: "Kepler-90 c", hostname: "Kepler-90")
      create(:exoplanet, pl_name: "Kepler-90 d", hostname: "Kepler-90")
      create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World")

      get systems_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Kepler-90")
      expect(response.body).to include("TRAPPIST-1")
      expect(response.body).not_to include("Lone World")
      expect(response.body.index("Kepler-90")).to be < response.body.index("TRAPPIST-1")
    end

    it "includes single-planet systems when all=1" do
      create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World")

      get systems_dataset_path(dataset), params: { all: "1" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Lone World")
    end

    it "links each system to the filtered chart+table view" do
      create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1")
      create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1")

      get systems_dataset_path(dataset)

      expect(response.body).to include(dataset_path(dataset, hostname: "TRAPPIST-1"))
    end

    it "links back to the unfiltered flat view" do
      get systems_dataset_path(dataset)

      expect(response.body).to include("All Planets")
      expect(response.body).to include(dataset_path(dataset))
    end

    it "shows an empty state when there is no host star data" do
      get systems_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no host star data.")
    end

    context "systems overview chart" do
      it "renders the chart with per-system averages" do
        create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 400.0)
        create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 300.0)

        get systems_dataset_path(dataset)

        expect(response.body).to include('data-controller="systems-chart"')
        points = systems_chart_points(response.body)
        expect(points).to eq([ { "hostname" => "TRAPPIST-1", "planet_count" => 2, "avg_distance" => 12.4, "avg_temp" => 350.0, "spectral_class" => nil } ])
      end

      it "excludes systems where no row has a usable distance or temperature" do
        create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 400.0)
        create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 300.0)
        create(:exoplanet, pl_name: "Kepler-90 b", hostname: "Kepler-90", sy_dist: nil, pl_eqt: nil)
        create(:exoplanet, pl_name: "Kepler-90 c", hostname: "Kepler-90", sy_dist: nil, pl_eqt: nil)

        get systems_dataset_path(dataset)

        points = systems_chart_points(response.body)
        expect(points.map { |p| p["hostname"] }).to eq([ "TRAPPIST-1" ])
        expect(response.body).to include("Kepler-90")
      end

      it "respects the multi-planet-only toggle" do
        create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World", sy_dist: 50.0, pl_eqt: 255.0)

        get systems_dataset_path(dataset)
        expect(systems_chart_points(response.body)).to eq([])

        get systems_dataset_path(dataset), params: { all: "1" }
        expect(systems_chart_points(response.body).map { |p| p["hostname"] }).to eq([ "Lone World" ])
      end

      it "colors systems by the host's spectral class when known" do
        create(:stellar_host, hostname: "TRAPPIST-1", st_spectype: "M8 V")
        create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 400.0)
        create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 300.0)

        get systems_dataset_path(dataset)

        points = systems_chart_points(response.body)
        expect(points.first["spectral_class"]).to eq("M")
      end
    end

    def systems_chart_points(body)
      match = body.match(/data-systems-chart-points-value="([^"]*)"/)
      return [] unless match

      JSON.parse(CGI.unescapeHTML(match[1]))
    end
  end

  describe "GET /datasets/:id/random" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    it "returns 404 for an unknown dataset" do
      get random_dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "renders a random row's values" do
      create(:exoplanet, pl_name: "Kepler-442 b")

      get random_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Kepler-442 b")
    end

    it "renders an empty state when there are no exoplanets" do
      get random_dataset_path(dataset)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no rows.")
    end
  end

  describe "GET /datasets/:id/extremes" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    it "returns 404 for an unknown dataset" do
      get extremes_dataset_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "ranks the hottest planets by pl_eqt descending" do
      create(:exoplanet, pl_name: "Warm World", pl_eqt: 500.0)
      create(:exoplanet, pl_name: "Scorcher", pl_eqt: 2000.0)

      get extremes_dataset_path(dataset)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Hottest")
      expect(response.body.index("Scorcher")).to be < response.body.index("Warm World")
    end

    it "ranks planets by closeness to Earth-size regardless of direction" do
      create(:exoplanet, pl_name: "Just Right", pl_rade: 1.1, pl_eqt: nil, disc_year: nil, sy_dist: nil)
      create(:exoplanet, pl_name: "Way Off", pl_rade: 9.0, pl_eqt: nil, disc_year: nil, sy_dist: nil)
      create(:exoplanet, pl_name: "Slightly Small", pl_rade: 0.8, pl_eqt: nil, disc_year: nil, sy_dist: nil)

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
