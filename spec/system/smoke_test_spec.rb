require "rails_helper"

RSpec.describe "Smoke test", type: :system do
  before do
    driven_by :headless_chrome
  end

  it "loads the homepage" do
    visit root_path
    expect(page).to have_content("Rowboat")
  end
end
