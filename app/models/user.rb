class User < ApplicationRecord
  enum :experience_level, { beginner: 0, intermediate: 1, advanced: 2, expert: 3 }

  has_many :owned_boats, class_name: "Boat", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :crew_memberships, dependent: :destroy
  has_many :boats, through: :crew_memberships

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
