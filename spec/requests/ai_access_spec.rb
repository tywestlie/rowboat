require "rails_helper"

RSpec.describe "AI access gate", type: :request do
  before do
    allow(AiCredentials).to receive(:access_code).and_return("open-sesame")
  end

  describe "GET /ask" do
    it "redirects to the access form when not authorized" do
      get ask_path
      expect(response).to redirect_to(new_ai_access_path)
    end

    it "is accessible once authorized" do
      post ai_access_path, params: { code: "open-sesame" }
      get ask_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /ask/access" do
    it "grants access and redirects to the question form on the correct code" do
      post ai_access_path, params: { code: "open-sesame" }

      expect(response).to redirect_to(ask_path)
      expect(session[:ai_authorized]).to be true
    end

    it "does not grant access on an incorrect code" do
      post ai_access_path, params: { code: "wrong" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(session[:ai_authorized]).to be_nil
    end
  end
end
