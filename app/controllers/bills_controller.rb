class BillsController < ApplicationController
  # layout "sb_admin"
  before_action :set_bill, only: [:show, :edit, :update, :destroy]
  before_action :set_chore_group, only: [:index, :new, :create]

  # GET /bills
  def index
    # @chore_group =
    #   if params[:chore_group_id].present?
    #     ChoreGroup.find_by(id: params[:chore_group_id])
    #   elsif Current&.user
    #     Current.user.members.includes(:chore_group).first&.chore_group
    #   end
    # @chore_group ||= ChoreGroup.first
    # raise ActiveRecord::RecordNotFound, "No ChoreGroup found" unless @chore_group

    # @current_member =
    #   if Current&.user
    #     @chore_group.members.find_by(user_id: Current.user.id)
    #   end
    # @current_member ||= @chore_group.members.first
    # raise ActiveRecord::RecordNotFound, "No Member in this group" unless @current_member

    @bills = Bill
      .where(chore_group_id: @chore_group.id)
      .includes(:member, bill_shares: :member) 
      .order(created_at: :desc)

    @bills_you_paid = @bills.where(member_id: @current_member.id)

    @your_shares = BillShare
      .joins(:bill)
      .includes(bill: [:member, :chore_group])
      .where(member_id: @current_member.id, bills: { chore_group_id: @chore_group.id })
      .order('bills.created_at DESC')


    @total_you_paid = @bills_you_paid.sum(:total_amount)
    @you_are_creditor_unpaid = BillShare
      .joins(:bill)
      .where(bills: { chore_group_id: @chore_group.id, member_id: @current_member.id })
      .where(status: 'unpaid')
      .where.not(member_id: @current_member.id)
      .sum(:amount)
    @you_owe_unpaid = BillShare
      .joins(:bill)
      .where(member_id: @current_member.id, status: 'unpaid', bills: { chore_group_id: @chore_group.id })
      .where.not(bills: { member_id: @current_member.id })
      .sum(:amount)
    involved_via_shares_count = BillShare
      .joins(:bill)
      .where(member_id: @current_member.id, bills: { chore_group_id: @chore_group.id })
      .select('DISTINCT bills.id')
      .count

    @involved_count = @bills_you_paid.count + involved_via_shares_count
  end


  # GET /bills/1
  def show; end

  # GET /bills/new
  def new
    @chore_group =
      if params[:chore_group_id].present?
        ChoreGroup.find_by(id: params[:chore_group_id])
      elsif Current&.user
        Current.user.members.includes(:chore_group).first&.chore_group
      end

    @chore_group ||= ChoreGroup.first
    raise ActiveRecord::RecordNotFound, "No ChoreGroup found" unless @chore_group

    @current_member =
      if Current&.user
        @chore_group.members.find_by(user_id: Current.user.id)
      end

    @current_member ||= @chore_group.members.first
    raise ActiveRecord::RecordNotFound, "No Member in this group" unless @current_member

    @bill = @chore_group.bills.build(member: @current_member)
    @members_for_split = @chore_group.members.includes(:user).order(:id)
  end



  # POST /bills
def create
  shared_member_ids = (params[:bill][:shared_member_ids] || []).reject(&:blank?).map(&:to_i)
  safe_params = bill_params.except(:shared_member_ids)

  @bill = Bill.new(safe_params)

  if @bill.save
    update_bill_shares(@bill, shared_member_ids)
    redirect_to chore_group_bills_path(@bill.chore_group), notice: "Bill created successfully."
  else
    @chore_group = @bill.chore_group
    @current_member = @bill.member
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

    if @bill.update(bill_params)
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
  end

  def set_chore_group
    @chore_group = ChoreGroup.find(params[:chore_group_id])
    @current_member = if Current&.user
      @chore_group.members.find_by(user_id: Current.user.id)
    end
    @current_member ||= @chore_group.members.first
    raise ActiveRecord::RecordNotFound, "No Member in this group" unless @current_member
  end


def bill_params
  params.require(:bill).permit(:chore_group_id, :member_id, :total_amount, :description)
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
    # selected_member_ids = params[:bill][:shared_member_ids].reject(&:blank?).map(&:to_i)
    selected_member_ids -= [bill.member_id] 

    existing_member_ids = bill.bill_shares.pluck(:member_id)

    members_to_add = selected_member_ids - existing_member_ids
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
