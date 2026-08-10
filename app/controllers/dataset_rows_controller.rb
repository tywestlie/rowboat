class DatasetRowsController < ApplicationController
  def show
    @dataset = Dataset.find(params[:dataset_id])
    @columns = @dataset.dataset_columns.order(:position)
    @row = @dataset.dataset_rows.find(params[:id])
  end
end
