class StellarHost < ApplicationRecord
  has_many :exoplanets, foreign_key: :hostname, primary_key: :hostname
end
