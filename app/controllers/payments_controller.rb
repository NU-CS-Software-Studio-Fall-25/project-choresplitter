class PaymentsController < ApplicationController
  before_action :set_chore_group

  def create
    @payee = @chore_group.members.find(params[:payment][:payee_id]) # The person receiving money (You)
    @payer = @chore_group.members.find(params[:payment][:payer_id]) # The person paying (Jack)
    amount = params[:payment][:amount].to_f

    @payment = Payment.new(
      chore_group: @chore_group,
      payer: @payer,
      payee: @payee,
      amount: amount,
      description: "Settlement via Settle Up button"
    )

    if @payment.save
      # Logic added here to actually update the debt status
      settle_debt(@payer, @payee, amount)

      redirect_to chore_group_bills_path(@chore_group), notice: "Settled up successfully!"
    else
      redirect_to chore_group_bills_path(@chore_group), alert: "Failed to settle up."
    end
  end

  private

  def set_chore_group
     @chore_group = ChoreGroup.find_by(code: params[:chore_group_id])
  end

  # Find unpaid bill shares and mark them as paid until the payment amount is used up
  def settle_debt(payer, payee, payment_amount)
    # Find all shares where the Payer owes money to the Payee
    shares = BillShare.joins(:bill)
                      .where(member_id: payer.id)            # The debtor
                      .where(bills: { member_id: payee.id }) # The creditor (bill owner)
                      .where(status: "unpaid")
                      .order("bills.created_at ASC")         # Settle oldest bills first

    remaining = payment_amount

    shares.each do |share|
      break if remaining <= 0.009 # Stop if payment is exhausted (accounting for float precision)

      if remaining >= share.amount
        # Case 1: Payment covers the entire share
        remaining -= share.amount
        share.update!(status: "paid")
      else
        # Case 2: Partial payment
        # We STOP processing the debt here. The BillShare record remains untouched
        # (amount=$10, status='unpaid'). The Payment history itself handles the offset.
        break
      end
    end
  end
end
