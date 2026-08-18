require "rails_helper"

RSpec.describe "Exoplanets", type: :request do
  describe "GET /exoplanets" do
    it "renders column headers and row values" do
      create(:exoplanet, pl_name: "Kepler-442 b", disc_year: 2015)

      get exoplanets_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Discovery Year")
      expect(response.body).to include("Kepler-442 b")
    end

    it "renders an empty state when there are no exoplanets" do
      get exoplanets_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no rows.")
    end

    it "links each planet to its show page" do
      exoplanet = create(:exoplanet, pl_name: "Kepler-442 b")

      get exoplanets_path

      expect(response.body).to include(exoplanet_path(exoplanet))
    end

    context "starfield visualization" do
      it "renders the starfield canvas in sky mode with numeric points cast server-side" do
        exoplanet = create(:exoplanet, pl_name: "Kepler-442 b", pl_rade: 1.34, sy_dist: 371.0, pl_eqt: 233.0, pl_orbper: nil)

        get exoplanets_path

        expect(response.body).to include('data-controller="starfield"')
        expect(response.body).to include('data-starfield-mode-value="sky"')
        points = starfield_points(response.body)
        expect(points).to eq([ { "id" => exoplanet.id, "pl_name" => "Kepler-442 b", "pl_rade" => 1.34, "sy_dist" => 371.0, "pl_eqt" => 233.0 } ])
      end

      it "excludes rows missing any of the three required fields" do
        create(:exoplanet, pl_name: "Complete", pl_rade: 1.0, sy_dist: 10.0, pl_eqt: 300.0)
        create(:exoplanet, pl_name: "Missing Distance", pl_rade: 1.0, sy_dist: nil, pl_eqt: 300.0)

        get exoplanets_path

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
        get exoplanets_path

        expect(response.body).to include("Planet 0")
        expect(response.body).not_to include("Planet 50")
        expect(response.body).to include("page=2")
      end

      it "shows the 51st row on page 2" do
        get exoplanets_path(page: 2)

        expect(response.body).to include("Planet 50")
      end
    end
  end

  describe "GET /exoplanets/:id" do
    it "returns 404 for an unknown exoplanet" do
      get exoplanet_path(id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "renders the planet's details" do
      exoplanet = create(:exoplanet, pl_name: "Kepler-442 b", disc_year: 2015)

      get exoplanet_path(exoplanet)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Kepler-442 b")
      expect(response.body).to include("Discovery Year")
    end

    it "links to the planet's system" do
      exoplanet = create(:exoplanet, pl_name: "Kepler-442 b", hostname: "Kepler-442")

      get exoplanet_path(exoplanet)

      expect(response.body).to include(system_path("Kepler-442"))
    end
  end

  describe "GET /exoplanets/random" do
    it "renders a random row's values" do
      create(:exoplanet, pl_name: "Kepler-442 b")

      get random_exoplanet_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Kepler-442 b")
    end

    it "renders an empty state when there are no exoplanets" do
      get random_exoplanet_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("This dataset has no rows.")
    end
  end
end
