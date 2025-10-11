class ChoreGroupsController < ApplicationController
  before_action :set_chore_group, only: [:show, :edit, :update, :destroy]

  def index
    @chore_groups = ChoreGroup.includes(:users).order(created_at: :desc)
  end

  def show; end

  def new
    @chore_group = ChoreGroup.new
  end

  def create
    @chore_group = ChoreGroup.new(chore_group_params)
    # @chore_group.admin = current_user
    if @chore_group.save
      redirect_to @chore_group, notice: "Chore group created."
    else
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
