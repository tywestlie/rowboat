class ExoplanetsController < ApplicationController
  def index
    @exoplanets = Exoplanet.order(:id).page(params[:page]).per(50)
    @starfield_points = starfield_points
  end

  def show
    @exoplanet = Exoplanet.find(params[:id])
  end

  def random
    @exoplanet = Exoplanet.order(Arel.sql("RANDOM()")).first
  end

  private

  def starfield_points
    Exoplanet.where.not(pl_rade: nil).where.not(sy_dist: nil).where.not(pl_eqt: nil)
      .pluck(:id, :pl_name, :pl_rade, :sy_dist, :pl_eqt)
      .map do |id, pl_name, pl_rade, sy_dist, pl_eqt|
        { id: id, pl_name: pl_name, pl_rade: pl_rade, sy_dist: sy_dist, pl_eqt: pl_eqt }
      end
  end
end
