require 'rails_helper'

RSpec.describe Dataset, type: :model do
  describe "#has_column?" do
    it "is true for a column that belongs to the dataset" do
      dataset = create(:dataset)
      create(:dataset_column, dataset: dataset, name: "pl_name")

      expect(dataset.has_column?("pl_name")).to be true
    end

    it "is false for a name that isn't one of the dataset's columns" do
      dataset = create(:dataset)

      expect(dataset.has_column?("not_a_real_column")).to be false
    end
  end
end
