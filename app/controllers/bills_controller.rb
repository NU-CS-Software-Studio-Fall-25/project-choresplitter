class BillsController < ApplicationController
  # layout "sb_admin"
  before_action :set_bill, only: [:show, :edit, :update, :destroy]
  before_action :set_chore_group_for_index, only: [:index]
  before_action :set_chore_group, only: [:new, :create]
  before_action :require_bill_owner, only: [:edit, :update]

  # GET /bills
  def index
    if @chore_group.present? && @current_member.present?
      # Bills within a single group where you're a member
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

      @you_are_creditor_unpaid = BillShare
        .joins(:bill)
        .where(bills: { chore_group_id: @chore_group.id, member_id: @current_member.id })
        .where(status: "unpaid")
        .where.not(member_id: @current_member.id)
        .sum(:amount)

      @you_owe_unpaid = BillShare
        .joins(:bill)
        .where(member_id: @current_member.id, status: "unpaid", bills: { chore_group_id: @chore_group.id })
        .where.not(bills: { member_id: @current_member.id })
        .sum(:amount)

      involved_via_shares_count = BillShare
        .joins(:bill)
        .where(member_id: @current_member.id, bills: { chore_group_id: @chore_group.id })
        .select("DISTINCT bills.id")
        .count

      @involved_count = you_paid_scope.count + involved_via_shares_count

    else
      # Global "My Bills" across all groups
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

      @you_are_creditor_unpaid = BillShare
        .joins(:bill)
        .where(status: "unpaid")
        .where(bills: { member_id: my_member_ids })
        .where.not(member_id: my_member_ids)
        .sum(:amount)

      @you_owe_unpaid = BillShare
        .joins(:bill)
        .where(member_id: my_member_ids, status: "unpaid")
        .where.not(bills: { member_id: my_member_ids })
        .sum(:amount)

      @involved_count = bills_scope.count
    end

    @pagy_paid, @bills_you_paid = pagy(:offset, you_paid_scope, items: 5, page_param: :page_paid)
    @pagy_owed, @your_shares    = pagy(:offset, your_shares_scope, items: 5, page_param: :page_owed)
  end

  # GET /bills/1
  def show; end

  # GET /bills/new
  def new
    # @chore_group and @current_member are set by set_chore_group
    @bill = @chore_group.bills.build(member: @current_member)
    @members_for_split = @chore_group.members.includes(:user).order(:id)
  end


  # POST /bills
  def create
    shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)

    # Use the chore_group and current_member from set_chore_group, not a raw :chore_group_id param
    safe_params = bill_params.except(:shared_member_ids, :chore_group_id)

    @bill = @chore_group.bills.build(safe_params)
    @bill.member ||= @current_member

    if @bill.save
      update_bill_shares(@bill, shared_member_ids)
      redirect_to chore_group_bills_path(@bill.chore_group), notice: "Bill created successfully."
    else
      @chore_group = @bill.chore_group || @chore_group
      @current_member ||= @bill.member
      @members_for_split = @chore_group.members.includes(:user).order(:id)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /bills/1/edit
  def edit
    @chore_group = @bill.chore_group
    @current_member = @bill.member
    @members_for_split = @chore_group.members.includes(:user).order(:id)
  end

  # PATCH/PUT /bills/1
  def update
    shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)

    if @bill.update(bill_params.except(:shared_member_ids))
      update_bill_shares(@bill, shared_member_ids)
      redirect_to bill_path(@bill), notice: "Bill updated successfully."
    else
      @chore_group = @bill.chore_group
      @current_member = @bill.member
      @members_for_split = @chore_group.members.includes(:user).order(:id)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /bills/1
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
      # If we came from a global route (/bills/new), pick a sensible default:
      # the first group the user is a member of, or fall back to the first group
      @chore_group =
        Current.user.members.includes(:chore_group).first&.chore_group ||
        ChoreGroup.first
    end

    raise ActiveRecord::RecordNotFound, "No ChoreGroup found" unless @chore_group

    @current_member =
      @chore_group.members.find_by(user_id: Current.user.id) ||
      @chore_group.members.first

    unless @current_member
      redirect_to root_path, alert: "You are not a member of this group." and return
    end
  end


  def set_chore_group_for_index
    unless Current&.user
      redirect_to root_path, alert: "You must sign in to view your bills." and return
    end

    # All groups the current user belongs to
    @user_groups = ChoreGroup
      .joins(:members)
      .where(members: { user_id: Current.user.id })
      .distinct

    if params[:chore_group_id].present?
      # chore_group_id is actually the CODE in your URLs
      @chore_group = @user_groups.find_by(code: params[:chore_group_id])

      if @chore_group
        # Safe, because we already filtered by membership
        @current_member = @chore_group.members.find_by(user_id: Current.user.id)
      else
        # Invalid code OR not one of the user's groups -> fall back to "all my bills"
        @chore_group   = nil
        @current_member = nil
        flash.now[:alert] = "That group could not be found or you are not a member of it."
      end
    else
      # Global "My Bills" view
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
      :chore_group_id,  # still allowed but we ignore it in create
      :member_id,
      :total_amount,
      :description,
      shared_member_ids: []
    )
  end

  def create_bill_shares_for_group(bill, selected_member_ids)
    return if selected_member_ids.nil?

    selected_member_ids -= [bill.member_id]
    members = Member.where(id: selected_member_ids)
    share_amount = (bill.total_amount / (members.size + 1)).round(2)

    members.each do |m|
      BillShare.create!(
        bill: bill,
        member: m,
        amount: share_amount,
        status: "unpaid"
      )
    end
  end

  def update_bill_shares(bill, selected_member_ids)
    selected_member_ids -= [bill.member_id]

    existing_member_ids = bill.bill_shares.pluck(:member_id)

    members_to_add    = selected_member_ids - existing_member_ids
    members_to_remove = existing_member_ids - selected_member_ids

    bill.bill_shares.where(member_id: members_to_remove).destroy_all

    total_people = selected_member_ids.size + 1
    share_amount = (bill.total_amount / total_people).round(2)

    bill.bill_shares.each do |share|
      share.update(amount: share_amount)
    end

    members_to_add.each do |member_id|
      BillShare.create!(
        bill: bill,
        member_id: member_id,
        amount: share_amount,
        status: "unpaid"
      )
    end
  end
end

