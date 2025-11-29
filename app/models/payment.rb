class Payment < ApplicationRecord
  belongs_to :chore_group
  belongs_to :payer, class_name: "Member"
  belongs_to :payee, class_name: "Member"

  validates :amount, numericality: { greater_than: 0 }

  after_create :reconcile_bill_shares

  private

  def reconcile_bill_shares
    unpaid_shares = BillShare.joins(:bill)
                             .where(member_id: payer_id, status: 'unpaid')
                             .where(bills: { member_id: payee_id })
                             .order('bills.created_at ASC')

    remaining_payment = amount

    unpaid_shares.each do |share|
      break if remaining_payment <= 0

      if share.amount <= remaining_payment
        share.update!(status: 'paid')
        remaining_payment -= share.amount
      else
        # new_amount = share.amount - remaining_payment
        # share.update!(amount: new_amount) 
        remaining_payment = 0
      end
    end
  end
end