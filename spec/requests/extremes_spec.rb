require "rails_helper"

RSpec.describe "Extremes", type: :request do
  describe "GET /extremes" do
    it "ranks the hottest planets by pl_eqt descending" do
      create(:exoplanet, pl_name: "Warm World", pl_eqt: 500.0)
      create(:exoplanet, pl_name: "Scorcher", pl_eqt: 2000.0)

      get extremes_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Hottest")
      expect(response.body.index("Scorcher")).to be < response.body.index("Warm World")
    end

    it "ranks planets by closeness to Earth-size regardless of direction" do
      create(:exoplanet, pl_name: "Just Right", pl_rade: 1.1, pl_eqt: nil, disc_year: nil, sy_dist: nil)
      create(:exoplanet, pl_name: "Way Off", pl_rade: 9.0, pl_eqt: nil, disc_year: nil, sy_dist: nil)
      create(:exoplanet, pl_name: "Slightly Small", pl_rade: 0.8, pl_eqt: nil, disc_year: nil, sy_dist: nil)

      get extremes_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Closest to Earth-size")
      body = response.body
      expect(body.index("Just Right")).to be < body.index("Slightly Small")
      expect(body.index("Slightly Small")).to be < body.index("Way Off")
    end

    it "renders an empty state for a leaderboard with no data" do
      get extremes_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("No data available.")
    end
  end
end
