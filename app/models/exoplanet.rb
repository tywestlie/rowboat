class Exoplanet < ApplicationRecord
  belongs_to :stellar_host, foreign_key: :hostname, primary_key: :hostname, optional: true
end
