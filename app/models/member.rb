class Member < ApplicationRecord
  belongs_to :user
  belongs_to :chore_group

  validates :role, presence: true
end
