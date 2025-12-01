class Invitation < ApplicationRecord
  belongs_to :chore_group
  belongs_to :sender,    class_name: "User"
  belongs_to :recipient, class_name: "User"

  STATUSES = %w[pending accepted declined].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :recipient_id, uniqueness: {
    scope: [ :chore_group_id, :status ],
    conditions: -> { where(status: "pending") },
    message: "already has a pending invite to this group"
  }

  scope :pending, -> { where(status: "pending") }
end
