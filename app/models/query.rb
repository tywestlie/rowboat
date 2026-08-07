class Query < ApplicationRecord
  belongs_to :dataset

  validates :question, presence: true
end
