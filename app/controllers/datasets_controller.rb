class DatasetsController < ApplicationController
  def index
    @datasets = Dataset.order(:name)
  end

  def show
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)
    @rows = @dataset.dataset_rows.order(:id).page(params[:page]).per(50)
  end
end
