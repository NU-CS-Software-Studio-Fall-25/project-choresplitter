class ChoreGroupsController < ApplicationController
  before_action :set_chore_group, only: [:show, :edit, :update, :destroy]

  def index
    @chore_groups = ChoreGroup.includes(:users).order(created_at: :desc)
  end

  def show; end

  def new_chore_group
    @chore_group = ChoreGroup.new
  end

  def create
    @chore_group = ChoreGroup.new(chore_group_params)
    @chore_group.admin = current_user
    if @chore_group.save
      @chore_group.task_groups.create!(chore_group_id: @chore_group.id)
      membership = @chore_group.members.build(
          user: current_user,
          role: "member",
          points: 0
      )
      @chore_group.bill.create!(
        member: membership,
        total_amount: 0,
        description: "Initial bill"        
      )
      if membership.save
        redirect_to chore_groups_path
        flash[:alert] = "Chore group created and joined: ID = #{@chore_group.id}"
      else
        redirect_to chore_groups_path
        flash[:alert] = "Chore group created, but unable to join: #{membership.errors.full_messages.to_sentence}"
      end
    else
      flash[:alert] = "Failed to create chore group: #{@chore_group.errors.full_messages.to_sentence}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @chore_group.update(chore_group_params)
      redirect_to @chore_group, notice: "Chore group updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def search
    @found_group = ChoreGroup.find_by(id: params[:search_id])

    if @found_group
      render :search
    else
      flash[:alert] = "No chore group with ID #{params[:search_id]}."
      redirect_to join_chore_groups_path
    end
  end

  def join
    if request.post?
      @chore_group = ChoreGroup.find_by(id: params[:id])

      if @chore_group.nil?
        flash.now[:alert] = "That chore group no longer exists."
        return render :join, status: :unprocessable_entity
      end

      membership = @chore_group.members.find_by(user: current_user)

      if membership
        redirect_to @chore_group
        flash[:alert] = "You are already a member."
      else
        membership = @chore_group.members.build(
          user: current_user,
          role: "member",
          points: 0
        )

        if membership.save
          redirect_to chore_groups_path
          flash[:alert] = "You joined #{@chore_group.name}!"
        else
          redirect_to chore_groups_path
          flash[:alert] = "Unable to join: #{membership.errors.full_messages.to_sentence}"
        end
      end
    else
      # GET request → just render search/join form
      render :join
    end
  end


  def leave
    #leave a specific choregroup

    #1. group doesn't exist
    @chore_group = ChoreGroup.find_by(id: params[:id])
    if @chore_group.nil?
      redirect_to chore_groups_path, alert: "This group does not exist."
      return
    end

    membership = @chore_group.members.find_by(user: current_user)

    # 2. Handle the case where the user is not a member
    if membership.nil?
      redirect_to @chore_group, alert: "You are not a member of this group."
      return
    end

    # 3. Prevent the admin from leaving the group
    if @chore_group.admin_id == current_user.id
      redirect_to @chore_group, alert: "Admins cannot leave their own group. Please delete the group or transfer ownership first."
      return
    end

    # 4. Destroy the membership and redirect
    if membership.destroy
      redirect_to chore_groups_path, notice: "You have successfully left '#{@chore_group.name}'."
    else
      # This case is rare but good to have for robustness
      redirect_to @chore_group, alert: "An error occurred while trying to leave the group."
    end

  end

  def destroy
    @chore_group.destroy
    redirect_to chore_groups_path, notice: "Chore group deleted."
  end

  private

  def set_chore_group
    @chore_group = ChoreGroup.find(params[:id])
  end

  def chore_group_params
    params.require(:chore_group).permit(:name, :admin_id)
  end
end
