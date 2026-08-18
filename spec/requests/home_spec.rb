require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders the landing page with a link into the systems list" do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Parallax")
      expect(response.body).to include(systems_path)
    end
  end
end
