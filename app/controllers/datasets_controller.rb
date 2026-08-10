class DatasetsController < ApplicationController
  def index
    @datasets = Dataset.order(:name)
  end

  STARFIELD_FIELDS = %w[pl_rade sy_dist pl_eqt].freeze

  def show
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)
    @rows = @dataset.dataset_rows.order(:id).page(params[:page]).per(50)
    @starfield_points = starfield_points if starfield_eligible?
  end

  def random
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)
    @row = @dataset.dataset_rows.order(Arel.sql("RANDOM()")).first
  end

  def extremes
    @dataset = Dataset.find(params[:id])
    @columns = @dataset.dataset_columns.order(:position)

    @leaderboards = {
      "Hottest" => numeric_top(:pl_eqt, :desc),
      "Coldest" => numeric_top(:pl_eqt, :asc),
      "Closest to Earth-size" => numeric_top(:pl_rade, :asc, distance_from: 1.0),
      "Most recently discovered" => numeric_top(:disc_year, :desc),
      "Closest to Earth" => numeric_top(:sy_dist, :asc)
    }
  end

  private

  def starfield_eligible?
    (STARFIELD_FIELDS - @columns.map(&:name)).empty?
  end

  def starfield_points
    @dataset.dataset_rows.pluck(:id, :data).filter_map do |id, data|
      next if STARFIELD_FIELDS.any? { |field| data[field].blank? }

      {
        id: id,
        pl_name: data["pl_name"],
        pl_rade: data["pl_rade"].to_f,
        sy_dist: data["sy_dist"].to_f,
        pl_eqt: data["pl_eqt"].to_f
      }
    end
  end

  def numeric_top(field, direction, distance_from: nil)
    field_expr = ActiveRecord::Base.sanitize_sql_array([ "data->>?", field.to_s ])
    cast = "(#{field_expr})::float"
    scope = @dataset.dataset_rows.where(Arel.sql("#{field_expr} IS NOT NULL"))

    order_expr = distance_from ? "ABS(#{cast} - #{distance_from})" : cast
    order_direction = distance_from ? :asc : direction

    scope.order(Arel.sql("#{order_expr} #{order_direction.to_s.upcase}")).limit(5)
  end
end
