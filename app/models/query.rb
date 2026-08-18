class Query < ApplicationRecord
  validates :question, presence: true
end
