require "rails_helper"

RSpec.describe "Systems", type: :request do
  describe "GET /systems" do
    it "lists multi-planet systems sorted by planet count descending, excluding single-planet systems" do
      create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1")
      create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1")
      create(:exoplanet, pl_name: "Kepler-90 b", hostname: "Kepler-90")
      create(:exoplanet, pl_name: "Kepler-90 c", hostname: "Kepler-90")
      create(:exoplanet, pl_name: "Kepler-90 d", hostname: "Kepler-90")
      create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World")

      get systems_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Kepler-90")
      expect(response.body).to include("TRAPPIST-1")
      expect(response.body).not_to include("Lone World")
      expect(response.body.index("Kepler-90")).to be < response.body.index("TRAPPIST-1")
    end

    it "includes single-planet systems when all=1" do
      create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World")

      get systems_path, params: { all: "1" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Lone World")
    end

    it "links each system to its show page" do
      create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1")
      create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1")

      get systems_path

      expect(response.body).to include(system_path("TRAPPIST-1"))
    end

    it "shows an empty state when there is no host star data" do
      get systems_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no host star data.")
    end

    context "systems overview chart" do
      it "renders the chart with per-system averages" do
        create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 400.0)
        create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 300.0)

        get systems_path

        expect(response.body).to include('data-controller="systems-chart"')
        points = systems_chart_points(response.body)
        expect(points).to eq([ { "hostname" => "TRAPPIST-1", "planet_count" => 2, "avg_distance" => 12.4, "avg_temp" => 350.0, "spectral_class" => nil } ])
      end

      it "excludes systems where no row has a usable distance or temperature" do
        create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 400.0)
        create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 300.0)
        create(:exoplanet, pl_name: "Kepler-90 b", hostname: "Kepler-90", sy_dist: nil, pl_eqt: nil)
        create(:exoplanet, pl_name: "Kepler-90 c", hostname: "Kepler-90", sy_dist: nil, pl_eqt: nil)

        get systems_path

        points = systems_chart_points(response.body)
        expect(points.map { |p| p["hostname"] }).to eq([ "TRAPPIST-1" ])
        expect(response.body).to include("Kepler-90")
      end

      it "respects the multi-planet-only toggle" do
        create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World", sy_dist: 50.0, pl_eqt: 255.0)

        get systems_path
        expect(systems_chart_points(response.body)).to eq([])

        get systems_path, params: { all: "1" }
        expect(systems_chart_points(response.body).map { |p| p["hostname"] }).to eq([ "Lone World" ])
      end

      it "colors systems by the host's spectral class when known" do
        create(:stellar_host, hostname: "TRAPPIST-1", st_spectype: "M8 V")
        create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 400.0)
        create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", sy_dist: 12.4, pl_eqt: 300.0)

        get systems_path

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

  describe "GET /systems/:hostname" do
    before do
      create(:exoplanet, pl_name: "TRAPPIST-1 b", hostname: "TRAPPIST-1", pl_rade: 1.12, sy_dist: 12.4, pl_eqt: 397.6, pl_orbper: 1.51)
      create(:exoplanet, pl_name: "TRAPPIST-1 c", hostname: "TRAPPIST-1", pl_rade: 1.10, sy_dist: 12.4, pl_eqt: 339.7, pl_orbper: 2.42)
      create(:exoplanet, pl_name: "Lone World b", hostname: "Lone World", pl_rade: 1.0, sy_dist: 50.0, pl_eqt: 255.0, pl_orbper: 365.0)
    end

    it "shows only the rows for the given host, with a system-mode starfield" do
      get system_path("TRAPPIST-1")

      expect(response.body).to include("Showing 2 planets around")
      expect(response.body).to include("TRAPPIST-1 b")
      expect(response.body).not_to include("Lone World b")
      expect(response.body).to include('data-starfield-mode-value="system"')
    end

    it "links back to the systems list" do
      get system_path("TRAPPIST-1")

      expect(response.body).to include("← All systems")
      expect(response.body).to include(systems_path)
    end

    it "shows an empty state for a host with no matches" do
      get system_path("Nonexistent")

      expect(response.body).to include("Showing 0 planets around")
      expect(response.body).to include("This dataset has no rows.")
    end

    it "shows the associated stellar host's details when one exists" do
      create(:stellar_host, hostname: "TRAPPIST-1", st_spectype: "M8 V", st_teff: 2559.0)

      get system_path("TRAPPIST-1")

      expect(response.body).to include("M8 V")
      expect(response.body).to include("2559")
    end
  end
end
