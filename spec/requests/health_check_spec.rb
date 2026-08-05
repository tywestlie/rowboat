require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "returns 200 from /up" do
    get "/up"
    expect(response).to have_http_status(:success)
  end
end