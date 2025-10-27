class Bill < ApplicationRecord
  belongs_to :chore_group
  belongs_to :member

  has_many :bill_shares, dependent: :destroy
  has_many :debtors, through: :bill_shares, source: :member

  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :description, presence: true
end
