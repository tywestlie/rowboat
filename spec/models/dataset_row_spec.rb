require 'rails_helper'

RSpec.describe DatasetRow, type: :model do
  describe "dynamic attribute accessors" do
    it "reads a value by the dataset column's name" do
      dataset = create(:dataset)
      create(:dataset_column, dataset: dataset, name: "pl_name")
      row = create(:dataset_row, dataset: dataset, data: { "pl_name" => "Kepler-22b" })

      expect(row.pl_name).to eq("Kepler-22b")
    end

    it "responds to methods named after the dataset's columns" do
      dataset = create(:dataset)
      create(:dataset_column, dataset: dataset, name: "pl_name")
      row = create(:dataset_row, dataset: dataset, data: { "pl_name" => "Kepler-22b" })

      expect(row.respond_to?(:pl_name)).to be true
    end

    it "raises NoMethodError for a method that isn't one of the dataset's columns" do
      row = create(:dataset_row)

      expect { row.not_a_real_column }.to raise_error(NoMethodError)
    end
  end
end
