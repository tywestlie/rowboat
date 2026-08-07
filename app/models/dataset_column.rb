class DatasetColumn < ApplicationRecord
  belongs_to :dataset

  validates :name, presence: true
  validates :data_type, presence: true, inclusion: { in: %w[string integer float date boolean] }
end
