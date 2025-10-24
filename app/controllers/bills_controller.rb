class BillsController < ApplicationController
  before_action :set_bill, only: [:show, :edit, :update, :destroy]

  # GET /bills
  def index
    @bills = Bill.includes(:member, :chore_group).order(created_at: :desc)

    if params[:chore_group_id].present?
      @bills = @bills.where(chore_group_id: params[:chore_group_id])
    end

    if params[:member_id].present?
      @bills = @bills.where(member_id: params[:member_id])
    end
  end

  # GET /bills/1
  def show; end

  # GET /bills/new
  def new
    @bill = Bill.new
  end

  # POST /bills
  def create
    @bill = Bill.new(bill_params)

    if @bill.save
      create_bill_shares_for_group(@bill)
      redirect_to @bill, notice: "Bill created and shared successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /bills/1/edit
  def edit; end

  # PATCH/PUT /bills/1
  def update
    if @bill.update(bill_params)
      update_bill_shares(@bill)
      redirect_to @bill, notice: "Bill updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /bills/1
  def destroy
    @bill.destroy
    redirect_to bills_path, notice: "Bill deleted successfully."
  end

  private

  def set_bill
    @bill = Bill.find(params[:id])
  end

  def bill_params
    params.require(:bill).permit(:chore_group_id, :member_id, :total_amount, :description, shared_member_ids: [])
  end


  def create_bill_shares_for_group(bill)
    selected_member_ids = params[:bill][:shared_member_ids].reject(&:blank?).map(&:to_i)
    return if selected_member_ids.empty?
    selected_member_ids -= [bill.member_id] 

    members = Member.where(id: selected_member_ids)

    share_amount = (bill.total_amount / (members.size + 1)).round(2)
    # share_amount = (bill.total_amount / members.size).round(2)

    members.each do |m|
      BillShare.create!(
        bill: bill,
        member: m,
        amount: share_amount,
        # status: (m == bill.member ? "paid" : "unpaid")
        status: "unpaid"
      )
    end
  end


  def update_bill_shares(bill)
    selected_member_ids = params[:bill][:shared_member_ids].reject(&:blank?).map(&:to_i)
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

