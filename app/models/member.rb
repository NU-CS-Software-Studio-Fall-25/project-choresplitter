class Member < ApplicationRecord
  belongs_to :user
  belongs_to :chore_group
  has_many :tasks, dependent: :nullify

  validates :role, presence: true
end
