class BillSharesController < ApplicationController
  before_action :set_bill_share, only: [ :show, :edit, :update, :destroy ]
  before_action :require_share_participant, only: [ :edit, :update ]
  # GET /bill_shares
  def index
    @bill_shares = if params[:bill_id].present?
      BillShare.where(bill_id: params[:bill_id])
    else
      BillShare.all
    end
  end

  # GET /bill_shares/1
  def show; end

  # GET /bill_shares/new
  def new
    @bill_share = BillShare.new
  end

  # POST /bill_shares
  def create
    @bill_share = BillShare.new(bill_share_params)

    if @bill_share.save
      redirect_to @bill_share, notice: "Bill share created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /bill_shares/1/edit
  def edit; end

  # PATCH/PUT /bill_shares/1
  def update
    if @bill_share.update(bill_share_params)
      redirect_to @bill_share, notice: "Bill share updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /bill_shares/1
  def destroy
    bill = @bill_share.bill
    @bill_share.destroy
    redirect_to bill_path(bill), notice: "Bill share deleted successfully."
  end

  private

  def set_bill_share
    @bill_share = BillShare.find(params[:id])
  end

  def bill_share_params
    params.require(:bill_share).permit(:bill_id, :member_id, :amount, :status)
  end

  def require_share_participant
    unless Current&.user
      redirect_to root_path, alert: "You must sign in to modify this share." and return
    end

    bill      = @bill_share.bill
    group     = bill.chore_group
    member    = group.members.find_by(user_id: Current.user.id)

    unless member
      redirect_to root_path, alert: "You are not a member of this group." and return
    end

    allowed_member_ids = [ @bill_share.member_id, bill.member_id ]

    unless allowed_member_ids.include?(member.id)
      redirect_to bill_path(bill), alert: "You are not allowed to update this share." and return
    end

    # unless @bill_share.member_id == member.id
    #   redirect_to bill_path(bill), alert: "Only the debtor can change this status." and return
    # end
  end
end
