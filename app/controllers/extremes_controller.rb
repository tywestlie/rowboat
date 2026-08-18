class ExtremesController < ApplicationController
  def index
    @leaderboards = {
      "Hottest" => Exoplanet.where.not(pl_eqt: nil).order(pl_eqt: :desc).limit(5),
      "Coldest" => Exoplanet.where.not(pl_eqt: nil).order(pl_eqt: :asc).limit(5),
      "Closest to Earth-size" => Exoplanet.where.not(pl_rade: nil).order(Arel.sql("ABS(pl_rade - 1.0) ASC")).limit(5),
      "Most recently discovered" => Exoplanet.where.not(disc_year: nil).order(disc_year: :desc).limit(5),
      "Closest to Earth" => Exoplanet.where.not(sy_dist: nil).order(sy_dist: :asc).limit(5)
    }
  end
end
