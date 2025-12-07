class BillsController < ApplicationController
  before_action :set_bill, only: [ :show, :edit, :update, :destroy ]
  before_action :set_chore_group_for_index, only: [ :index ]
  before_action :set_chore_group, only: [ :new, :create ]
  before_action :require_bill_owner, only: [ :edit, :update ]

  def index
    if @chore_group.present? && @current_member.present?
      @member_balances = []
      # You can keep *all* members here so old debts still show, including removed members
      other_members = @chore_group.members.where.not(id: @current_member.id)

      other_members.each do |m|
        balance = @current_member.net_balance_with(m)
        if balance.abs > 0.01
          @member_balances << { member: m, balance: balance }
        end
      end

      @you_are_creditor_unpaid = @member_balances.sum { |b| b[:balance] > 0 ? b[:balance] : 0 }
      @you_owe_unpaid          = @member_balances.sum { |b| b[:balance] < 0 ? b[:balance].abs : 0 }

      bills_scope = Bill
        .where(chore_group_id: @chore_group.id)
        .includes(:member, bill_shares: :member)
        .order(created_at: :desc)

      you_paid_scope = bills_scope.where(member_id: @current_member.id)

      your_shares_scope = BillShare
        .joins(:bill)
        .includes(bill: [ :member, :chore_group ])
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
      # Only consider *active* memberships for the current user
      my_member_ids = Current.user.members.where(removed_at: nil).pluck(:id)

      bills_scope = Bill
        .left_joins(:bill_shares)
        .includes(:member, bill_shares: :member)
        .where("bills.member_id IN (?) OR bill_shares.member_id IN (?)", my_member_ids, my_member_ids)
        .order(created_at: :desc)
        .distinct

      you_paid_scope = bills_scope.where(member_id: my_member_ids)

      your_shares_scope = BillShare
        .joins(:bill)
        .includes(bill: [ :member, :chore_group ])
        .where(member_id: my_member_ids)
        .order("bills.created_at DESC")

      @total_you_paid = you_paid_scope.sum(:total_amount)

      # 1. Total Debts Owed TO ME (By others in all groups)
      debt_owed_to_me = BillShare
        .joins(:bill)
        .where(bills: { member_id: my_member_ids })
        .where.not(member_id: my_member_ids)
        .sum(:amount)

      # 2. Total Debts Owed BY ME (To others in all groups)
      debt_owed_by_me = BillShare
        .joins(:bill)
        .where(member_id: my_member_ids)
        .where.not(bills: { member_id: my_member_ids })
        .sum(:amount)

      # 3. Payments I Received
      payments_i_received = Payment
        .where(payee_id: my_member_ids)
        .sum(:amount)

      # 4. Payments I Made
      payments_i_made = Payment
        .where(payer_id: my_member_ids)
        .sum(:amount)

      # 5. Final Calculation
      global_net = debt_owed_to_me - debt_owed_by_me + payments_i_made - payments_i_received

      if global_net > 0
        @you_are_creditor_unpaid = global_net
        @you_owe_unpaid          = 0
      else
        @you_are_creditor_unpaid = 0
        @you_owe_unpaid          = global_net.abs
      end

      @involved_count = bills_scope.count

      payments_scope = Payment
        .includes(:payer, :payee, :chore_group)
        .where("payer_id IN (?) OR payee_id IN (?)", my_member_ids, my_member_ids)
        .order(created_at: :desc)
    end

    @pagy_paid,     @bills_you_paid = pagy(:offset, you_paid_scope, items: 5,  page_param: :page_paid)
    @pagy_owed,     @your_shares    = pagy(:offset, your_shares_scope, items: 5, page_param: :page_owed)
    @pagy_payments, @payments       = pagy(:offset, payments_scope, items: 10, page_param: :page_payments)
  end

  def show; end

  def new
    @bill = @chore_group.bills.build(member: @current_member)
    # Only active members are available to split with
    @members_for_split = @chore_group.active_members.includes(:user).order(:id)
  end

  def create
    split_mode        = params[:bill][:split_mode] || "equal"
    shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)
    manual_amounts    = params[:bill][:manual_amounts] || {}

    safe_params = bill_params.except(:shared_member_ids, :manual_amounts, :split_mode)

    @bill = @chore_group.bills.build(safe_params)
    @bill.member ||= @current_member

    if @bill.save
      update_bill_shares(@bill, shared_member_ids, manual_amounts, split_mode)
      redirect_to chore_group_bills_path(@bill.chore_group), notice: "Bill created successfully."
    else
      @chore_group      = @bill.chore_group || @chore_group
      @current_member ||= @bill.member
      # Rebuild the active members list on error as well
      @members_for_split = @chore_group.active_members.includes(:user).order(:id)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @chore_group      = @bill.chore_group
    @current_member   = @bill.member
    # Again, only active members should be targetable on edit
    @members_for_split = @chore_group.active_members.includes(:user).order(:id)
  end

  def update
    split_mode        = params[:bill][:split_mode] || "equal"
    shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)
    manual_amounts    = params[:bill][:manual_amounts] || {}

    if @bill.update(bill_params.except(:shared_member_ids, :manual_amounts, :split_mode))
      update_bill_shares(@bill, shared_member_ids, manual_amounts, split_mode)
      redirect_to bill_path(@bill), notice: "Bill updated successfully."
    else
      @chore_group      = @bill.chore_group
      @current_member   = @bill.member
      @members_for_split = @chore_group.active_members.includes(:user).order(:id)
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
    @bill        = Bill.includes(:member, bill_shares: :member).find(params[:id])
    @chore_group = @bill.chore_group

    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view this bill." and return
    end

    # Only allow *active* members of the group to see the bill
    @current_member = @chore_group.active_members.find_by(user_id: Current.user.id)

    unless @current_member
      redirect_to root_path, alert: "You are not an active member of this group." and return
    end
  end

  def set_chore_group
    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view this group." and return
    end

    if params[:chore_group_id].present?
      @chore_group = ChoreGroup.find_by!(code: params[:chore_group_id])
    else
      # Fallback: first group where the user has an active membership
      @chore_group = Current.user.members
                               .where(removed_at: nil)
                               .includes(:chore_group)
                               .first&.chore_group
    end

    raise ActiveRecord::RecordNotFound, "No ChoreGroup found" unless @chore_group

    # Must be an *active* member of this chore group
    @current_member = @chore_group.active_members.find_by(user_id: Current.user.id)

    unless @current_member
      redirect_to root_path, alert: "You are not an active member of this group." and return
    end
  end

  def set_chore_group_for_index
    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view your bills." and return
    end

    # Only groups where the user has an active membership
    @user_groups = ChoreGroup
      .joins(:members)
      .where(members: { user_id: Current.user.id, removed_at: nil })
      .distinct

    if params[:chore_group_id].present?
      @chore_group = @user_groups.find_by(code: params[:chore_group_id])

      if @chore_group
        @current_member = @chore_group.active_members.find_by(user_id: Current.user.id)
      else
        @chore_group    = nil
        @current_member = nil
        flash.now[:alert] = "That group could not be found or you are not a member of it."
      end
    else
      @chore_group    = nil
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
      :split_mode,
      shared_member_ids: [],
      manual_amounts: {}
    )
  end

  def update_bill_shares(bill, selected_member_ids, manual_amounts, split_mode)
    selected_member_ids = selected_member_ids.map(&:to_i)
    # Prevent adding the payer as a debtor
    selected_member_ids -= [ bill.member_id ]

    Bill.transaction do
      # Remove shares that are no longer selected
      bill.bill_shares.where.not(member_id: selected_member_ids).destroy_all

      bill.bill_shares.reload

      if split_mode != "manual"
        total_people      = selected_member_ids.size + 1
        equal_share_amount = total_people > 0 ? (bill.total_amount / total_people).round(2) : 0
      end

      selected_member_ids.each do |mid|
        share = BillShare.find_or_initialize_by(bill_id: bill.id, member_id: mid)

        if split_mode == "manual"
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
