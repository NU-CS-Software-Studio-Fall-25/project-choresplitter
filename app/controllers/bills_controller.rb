class BillsController < ApplicationController
  before_action :set_bill, only: [:show, :edit, :update, :destroy]
  before_action :set_chore_group_for_index, only: [:index]
  before_action :set_chore_group, only: [:new, :create]
  before_action :require_bill_owner, only: [:edit, :update]

  def index
    if @chore_group.present? && @current_member.present?
      @member_balances = []
      other_members = @chore_group.members.where.not(id: @current_member.id)
      
      other_members.each do |m|
        balance = @current_member.net_balance_with(m) 
        if balance.abs > 0.01 
          @member_balances << { member: m, balance: balance }
        end
      end
      
      # These calculations rely on the results of net_balance_with, which is now correct
      @you_are_creditor_unpaid = @member_balances.sum { |b| b[:balance] > 0 ? b[:balance] : 0 }
      @you_owe_unpaid = @member_balances.sum { |b| b[:balance] < 0 ? b[:balance].abs : 0 }

      bills_scope = Bill
        .where(chore_group_id: @chore_group.id)
        .includes(:member, bill_shares: :member)
        .order(created_at: :desc)

      you_paid_scope = bills_scope.where(member_id: @current_member.id)

      your_shares_scope = BillShare
        .joins(:bill)
        .includes(bill: [:member, :chore_group])
        .where(member_id: @current_member.id, bills: { chore_group_id: @chore_group.id })
        .order("bills.created_at DESC")
      
      @total_you_paid = you_paid_scope.sum(:total_amount)

      involved_via_shares_count = BillShare
        .joins(:bill)
        .where(member_id: @current_member.id, bills: { chore_group_id: @chore_group.id })
        .select("DISTINCT bills.id")
        .count

      @involved_count = you_paid_scope.count + involved_via_shares_count

      payments_scope = @chore_group.payments
                                  .includes(:payer, :payee)
                                  .order(created_at: :desc)

    else
      my_member_ids = Current.user.members.pluck(:id)

      bills_scope = Bill
        .left_joins(:bill_shares)
        .includes(:member, bill_shares: :member)
        .where("bills.member_id IN (?) OR bill_shares.member_id IN (?)", my_member_ids, my_member_ids)
        .order(created_at: :desc)
        .distinct

      you_paid_scope = bills_scope.where(member_id: my_member_ids)

      your_shares_scope = BillShare
        .joins(:bill)
        .includes(bill: [:member, :chore_group])
        .where(member_id: my_member_ids)
        .order("bills.created_at DESC")

      @total_you_paid = you_paid_scope.sum(:total_amount)

      # 1. Total Debts Owed TO ME (By others in all groups)
      # This is the sum of all Bill Shares where the current user (my_member_ids) is the payer (creditor).
      debt_owed_to_me = BillShare
        .joins(:bill)
        .where(bills: { member_id: my_member_ids })
        .where.not(member_id: my_member_ids)
        .sum(:amount)

      # 2. Total Debts Owed BY ME (To others in all groups)
      # This is the sum of all Bill Shares where the current user (my_member_ids) is the debtor (member_id).
      debt_owed_by_me = BillShare
        .joins(:bill)
        .where(member_id: my_member_ids)
        .where.not(bills: { member_id: my_member_ids })
        .sum(:amount)

      # 3. Payments I Received (Reduces the debt owed TO ME)
      payments_i_received = Payment
        .where(payee_id: my_member_ids)
        .sum(:amount)

      # 4. Payments I Made (Reduces the debt owed BY ME)
      payments_i_made = Payment
        .where(payer_id: my_member_ids)
        .sum(:amount)

      # 5. Final Calculation: Netting the balances
      
      # Net Credit (Others Owe Me) = (Total Debt Owed To Me) - (Payments I Received) - (Debt I Paid Off via Payments I Made)
      # Note: If payments I made are greater than my debt, they represent overpayment/credit toward future debts.
      
      # Global Net Balance: (Debts owed TO me) - (Debts owed BY me) + (Payments I made) - (Payments I received)
      global_net = debt_owed_to_me - debt_owed_by_me + payments_i_made - payments_i_received
      
      # Assigning the correct values to the display variables
      if global_net > 0
        # If net is positive, others owe me (I am the creditor)
        @you_are_creditor_unpaid = global_net
        @you_owe_unpaid = 0
      else
        # If net is negative, I owe others (I am the debtor)
        @you_are_creditor_unpaid = 0
        @you_owe_unpaid = global_net.abs # Use absolute value for display
      end

      @involved_count = bills_scope.count

      payments_scope = Payment.includes(:payer, :payee, :chore_group)
                              .where("payer_id IN (?) OR payee_id IN (?)", my_member_ids, my_member_ids)
                              .order(created_at: :desc)
    end

    @pagy_paid, @bills_you_paid = pagy(:offset, you_paid_scope, items: 5, page_param: :page_paid)
    @pagy_owed, @your_shares = pagy(:offset, your_shares_scope, items: 5, page_param: :page_owed)
    @pagy_payments, @payments = pagy(:offset, payments_scope, items: 10, page_param: :page_payments)
  end

  def show; end

  def new
    @bill = @chore_group.bills.build(member: @current_member)
    @members_for_split = @chore_group.members.includes(:user).order(:id)
  end

  def create
    # 1. Capture split_mode from params (defaults to equal if missing)
    split_mode = params[:bill][:split_mode] || 'equal'
    
    shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)
    manual_amounts = params[:bill][:manual_amounts] || {}

    safe_params = bill_params.except(:shared_member_ids, :manual_amounts, :split_mode)

    @bill = @chore_group.bills.build(safe_params)
    @bill.member ||= @current_member

    if @bill.save
      # 2. Pass split_mode to the update logic
      update_bill_shares(@bill, shared_member_ids, manual_amounts, split_mode)
      redirect_to chore_group_bills_path(@bill.chore_group), notice: "Bill created successfully."
    else
      @chore_group = @bill.chore_group || @chore_group
      @current_member ||= @bill.member
      @members_for_split = @chore_group.members.includes(:user).order(:id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @chore_group = @bill.chore_group
    @current_member = @bill.member
    @members_for_split = @chore_group.members.includes(:user).order(:id)
  end

  def update
    split_mode = params[:bill][:split_mode] || 'equal'
    shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)
    manual_amounts = params[:bill][:manual_amounts] || {}

    if @bill.update(bill_params.except(:shared_member_ids, :manual_amounts, :split_mode))
      update_bill_shares(@bill, shared_member_ids, manual_amounts, split_mode)
      redirect_to bill_path(@bill), notice: "Bill updated successfully."
    else
      @chore_group = @bill.chore_group
      @current_member = @bill.member
      @members_for_split = @chore_group.members.includes(:user).order(:id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    group = @bill.chore_group
    @bill.destroy
    redirect_to chore_group_bills_path(group), notice: "Bill deleted successfully."
  end

  private

  def set_bill
    @bill = Bill.includes(:member, bill_shares: :member).find(params[:id])
    @chore_group = @bill.chore_group

    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view this bill." and return
    end

    @current_member = @chore_group.members.find_by(user_id: Current.user.id)

    unless @current_member
      redirect_to root_path, alert: "You are not a member of this group." and return
    end
  end

  def set_chore_group
    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view this group." and return
    end

    if params[:chore_group_id].present?
      @chore_group = ChoreGroup.find_by!(code: params[:chore_group_id])
    else
      @chore_group = Current.user.members.includes(:chore_group).first&.chore_group || ChoreGroup.first
    end

    raise ActiveRecord::RecordNotFound, "No ChoreGroup found" unless @chore_group

    @current_member = @chore_group.members.find_by(user_id: Current.user.id) || @chore_group.members.first

    unless @current_member
      redirect_to root_path, alert: "You are not a member of this group." and return
    end
  end

  def set_chore_group_for_index
    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view your bills." and return
    end

    @user_groups = ChoreGroup.joins(:members).where(members: { user_id: Current.user.id }).distinct

    if params[:chore_group_id].present?
      @chore_group = @user_groups.find_by(code: params[:chore_group_id])

      if @chore_group
        @current_member = @chore_group.members.find_by(user_id: Current.user.id)
      else
        @chore_group   = nil
        @current_member = nil
        flash.now[:alert] = "That group could not be found or you are not a member of it."
      end
    else
      @chore_group   = nil
      @current_member = nil
    end
  end

  def require_bill_owner
    unless @bill.member_id == @current_member.id
      redirect_to bill_path(@bill), alert: "Only the bill creator can edit this bill."
    end
  end

  def bill_params
    params.require(:bill).permit(
      :chore_group_id,
      :member_id,
      :total_amount,
      :description,
      :split_mode, # Make sure this is permitted
      shared_member_ids: [],
      manual_amounts: {}
    )
  end

  def update_bill_shares(bill, selected_member_ids, manual_amounts, split_mode)
    selected_member_ids = selected_member_ids.map(&:to_i)
    selected_member_ids -= [bill.member_id]

    Bill.transaction do
      bill.bill_shares.where.not(member_id: selected_member_ids).destroy_all
      
      bill.bill_shares.reload

      if split_mode != 'manual'
        total_people = selected_member_ids.size + 1
        equal_share_amount = total_people > 0 ? (bill.total_amount / total_people).round(2) : 0
      end

      selected_member_ids.each do |mid|
        share = BillShare.find_or_initialize_by(bill_id: bill.id, member_id: mid)
        
        if split_mode == 'manual'
          share.amount = manual_amounts[mid.to_s].to_f
        else
          share.amount = equal_share_amount
        end
        share.status = "unpaid" if share.new_record?
        
        share.save!
      end
    end
  end
end