class Boat < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :owned_boats

  has_many :crew_memberships, dependent: :destroy
  has_many :crew, through: :crew_memberships, source: :user

  validates :name, presence: true
end
