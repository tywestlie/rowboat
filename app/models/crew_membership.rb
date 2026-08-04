class CrewMembership < ApplicationRecord
  belongs_to :user
  belongs_to :boat

  enum :role, { crew: 0, first_mate: 1, captain: 2 }
  enum :status, { pending: 0, accepted: 1, declined: 2 }

  validates :user_id, uniqueness: { scope: :boat_id }
end
