class ChoreGroupsController < ApplicationController
  # Load by CODE instead of numeric id
  before_action :set_chore_group, only: [ :show, :edit, :update, :destroy, :leave ]

  def index
    @chore_groups = ChoreGroup.includes(:users).order(created_at: :desc)
  end

  def show
    # Must be a member to view this group
    @current_member = @chore_group.members.find_by(user_id: current_user.id)

    unless @current_member
      redirect_to chore_groups_path, alert: "You must be a member of this group to view it."
      return
    end

    # Determine if the current user is an admin of this group
    @is_admin = admin_of_group?(@chore_group, @current_member, current_user)

    # Tabs: allow "admin" only if @is_admin
    requested_tab = params[:tab].to_s
    @tab =
      if requested_tab == "admin"
        @is_admin ? "admin" : "overview"
      else
        requested_tab.presence_in(%w[overview my_tasks]) || "overview"
      end

    # All tasks in this chore group assigned to this member
    scope =
      if @current_member
        Task
          .joins(:task_group)
          .where(task_group: { chore_group_id: @chore_group.id })
          .where(member_id: @current_member.id)
      else
        Task.none
      end

    @pagy_my, @my_tasks = pagy(
      scope.order(created_at: :desc),
      page_param: "my_tasks_page",
      limit: 10
    )

    @pagy, @tasks = pagy(
      :offset,
      @chore_group.tasks.includes(:member).order(created_at: :desc),
      page_param: "overview_tasks_page",
      limit: 5
    )
  end

  def new_chore_group
    @chore_group = ChoreGroup.new
  end

  def create
    @chore_group = ChoreGroup.new(chore_group_params)
    @chore_group.admin = current_user
    admin_name = params.dig(:chore_group, :admin_name).presence
    @chore_group.admin_name = admin_name

    if @chore_group.save
      @chore_group.task_groups.create!(chore_group_id: @chore_group.id)

      membership = @chore_group.members.build(
        user: current_user,
        role: "member",
        points: 0,
        name: admin_name
      )

      @chore_group.bills.create!(
        member: membership,
        total_amount: 0,
        description: "Initial bill"
      )

      if membership.save
        flash[:alert] = "Chore group created and joined: Code = #{@chore_group.code}"
        redirect_to chore_groups_path
      else
        flash[:alert] = "Chore group created, but unable to join: #{membership.errors.full_messages.to_sentence}"
        redirect_to chore_groups_path
      end
    else
      flash[:alert] = "Failed to create chore group: #{@chore_group.errors.full_messages.to_sentence}"
      render :new_chore_group, status: :unprocessable_entity
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
    code = params[:search_code].presence || params[:search_id].presence
    @found_group = code.present? ? ChoreGroup.find_by(code: code) : nil

    if @found_group
      render :search
    else
      flash[:alert] = "No chore group with code #{code}."
      redirect_to join_chore_groups_path
    end
  end

  def join
    if request.get? || request.head?
      # /chore_groups/join => render the search form
      return render :join
    end

    # POSTs:
    group =
      if params[:id].present?
        # member route: /chore_groups/:id/join   (id is the 5-char code)
        ChoreGroup.find_by(code: params[:id])
      else
        # collection route: /chore_groups/join   (form submits :search_code)
        code = params[:search_code].presence || params[:search_id].presence
        ChoreGroup.find_by(code: code)
      end

    unless group
      redirect_to join_chore_groups_path, alert: "That chore group no longer exists." and return
    end

    member_name = params[:member_name].presence
    membership  = group.members.find_by(user: current_user)

    if membership
      membership.update(name: member_name) if member_name
      redirect_to group, notice: "You are already a member."
    else
      membership = group.members.build(user: current_user, role: "member", points: 0, name: member_name)
      if membership.save
        redirect_to group, notice: "You joined #{group.name}!"
      else
        redirect_to join_chore_groups_path, alert: "Unable to join: #{membership.errors.full_messages.to_sentence}"
      end
    end
  end

  # Member route: POST/DELETE /chore_groups/:id/leave (id is CODE)
  def leave
    # group already loaded by code
    membership = @chore_group.members.find_by(user: current_user)

    if membership.nil?
      redirect_to @chore_group, alert: "You are not a member of this group."
      return
    end

    if @chore_group.admin_id == current_user.id
      redirect_to @chore_group, alert: "Admins cannot leave their own group. Please delete the group or transfer ownership first."
      return
    end

    if membership.destroy
      redirect_to chore_groups_path, notice: "You have successfully left '#{@chore_group.name}'."
    else
      redirect_to @chore_group, alert: "An error occurred while trying to leave the group."
    end
  end

  def destroy
    @chore_group.destroy
    redirect_to chore_groups_path, notice: "Chore group deleted."
  end

  private

  def set_chore_group
    identifier = params[:id].presence || params[:chore_group_id].presence || params[:code].presence
    @chore_group = ChoreGroup.find_by!(code: identifier)
  rescue ActiveRecord::RecordNotFound
    redirect_to chore_groups_path, alert: "That chore group no longer exists."
  end

  def chore_group_params
    # admin_name is set separately above; keep permitted attributes for the model here
    params.require(:chore_group).permit(:name, :admin_id, :admin_name)
  end

  # Helper to decide admin status regardless of schema flavor
  def admin_of_group?(group, member, user)
    return false unless user

    # Priority 1: explicit group owner/admin id
    return true if group.respond_to?(:admin_id) && group.admin_id == user.id

    # Priority 2: member role flags on the membership
    return true if member&.respond_to?(:role) && member.role == "admin"
    return true if member&.respond_to?(:is_admin?) && member.is_admin?

    false
  end
end
