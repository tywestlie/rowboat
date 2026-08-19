require "rails_helper"

RSpec.describe Query, type: :model do
  it "requires a question" do
    query = Query.new(question: nil)
    expect(query).not_to be_valid
    expect(query.errors[:question]).to be_present
  end

  it "is valid with just a question" do
    expect(build(:query)).to be_valid
  end
end
