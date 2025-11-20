class MembersController < ApplicationController
  before_action :set_chore_group
  before_action :set_current_member
  before_action :ensure_admin!
  before_action :set_member, only: [:destroy]

  # Optional: list members for an Admin tab or API
  def index
    @members = @chore_group.members.includes(:user).order(created_at: :asc)

    respond_to do |format|
      format.html # renders app/views/members/index.html.erb if present
      format.json { render json: @members.as_json(only: [:id, :name, :user_id, :created_at]) }
    end
  end

  # DELETE /chore_groups/:chore_group_id/members/:id
  def destroy
    # Don’t allow removing the group owner/admin
    if owner_member?(@member)
      redirect_back fallback_location: chore_group_path(@chore_group, tab: "admin"),
                    alert: "You can’t remove the group owner." and return
    end

    # Don’t allow an admin to kick themselves by accident
    if @member.user_id == current_user.id
      redirect_back fallback_location: chore_group_path(@chore_group, tab: "admin"),
                    alert: "You can’t remove yourself." and return
    end

    if @member.destroy
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  notice: "Member removed from the group."
    else
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  alert: @member.errors.full_messages.to_sentence.presence || "Failed to remove member."
    end
  end

  private

  # :chore_group_id in routes is the group's CODE in your app
  def set_chore_group
    code = params[:chore_group_id].presence || params[:id].presence
    @chore_group = ChoreGroup.find_by!(code: code)
  rescue ActiveRecord::RecordNotFound
    redirect_to chore_groups_path, alert: "That chore group no longer exists."
  end

  def set_current_member
    @current_member = @chore_group.members.find_by(user_id: current_user.id)
  end

  def set_member
    @member = @chore_group.members.find(params[:id])
  end

  def ensure_admin!
    unless admin_of_group?(@chore_group, @current_member, current_user)
      redirect_to chore_group_path(@chore_group), alert: "Admins only." and return
    end
  end

  # Mirrors the helper you added in ChoreGroupsController
  def admin_of_group?(group, membership, user)
    return false unless user
    return true if group.respond_to?(:admin_id) && group.admin_id == user.id
    return true if membership&.respond_to?(:role) && membership.role == "admin"
    return true if membership&.respond_to?(:is_admin?) && membership.is_admin?
    false
  end

  def owner_member?(member)
    return false unless member
    # If you store owner via group.admin_id
    return true if @chore_group.respond_to?(:admin_id) && member.user_id == @chore_group.admin_id
    # Or via a role/flag on the membership
    return true if member.respond_to?(:role) && member.role == "admin"
    return true if member.respond_to?(:is_admin?) && member.is_admin?
    false
  end
end
