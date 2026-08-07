class Dataset < ApplicationRecord
  has_many :dataset_columns, dependent: :destroy
  has_many :dataset_rows, dependent: :destroy
  has_many :queries, dependent: :destroy

  validates :name, presence: true
end
