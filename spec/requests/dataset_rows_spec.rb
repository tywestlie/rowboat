require "rails_helper"

RSpec.describe "DatasetRows", type: :request do
  describe "GET /datasets/:dataset_id/rows/:id" do
    let(:dataset) { create(:dataset, name: "Confirmed Exoplanets") }

    before do
      create(:dataset_column, dataset: dataset, name: "pl_name", display_name: "Planet Name", data_type: "string", position: 0)
    end

    it "returns 404 for an unknown dataset" do
      row = create(:dataset_row, dataset: dataset)
      get dataset_row_path(dataset_id: "does-not-exist", id: row.id)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for an unknown row" do
      get dataset_row_path(dataset_id: dataset.id, id: "does-not-exist")
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when the row belongs to a different dataset" do
      other_dataset = create(:dataset)
      row = create(:dataset_row, dataset: other_dataset)

      get dataset_row_path(dataset_id: dataset.id, id: row.id)

      expect(response).to have_http_status(:not_found)
    end

    it "renders the row's values labeled with the column display name" do
      row = create(:dataset_row, dataset: dataset, data: { "pl_name" => "Kepler-442 b" })

      get dataset_row_path(dataset_id: dataset.id, id: row.id)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Planet Name")
      expect(response.body).to include("Kepler-442 b")
    end
  end
end
