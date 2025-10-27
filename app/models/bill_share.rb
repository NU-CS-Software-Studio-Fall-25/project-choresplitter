class BillShare < ApplicationRecord
  belongs_to :bill
  belongs_to :member

  STATUSES = %w[unpaid paid].freeze

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: STATUSES }
end
