class Member < ApplicationRecord
  belongs_to :user
  belongs_to :chore_group
  has_many :tasks, dependent: :nullify

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :chore_group_id }

  def net_balance_with(other_member)
    others_debt = BillShare.joins(:bill)
                           .where(member_id: other_member.id)
                           .where(bills: { member_id: self.id })
                           .sum(:amount)

    my_debt = BillShare.joins(:bill)
                       .where(member_id: self.id)
                       .where(bills: { member_id: other_member.id })
                       .sum(:amount)

    initial_balance = others_debt - my_debt

    payments_i_made = Payment.where(payer: self, payee: other_member).sum(:amount)

    payments_they_made = Payment.where(payer: other_member, payee: self).sum(:amount)

    final_balance = initial_balance - payments_they_made + payments_i_made
    
    return final_balance
  end
end