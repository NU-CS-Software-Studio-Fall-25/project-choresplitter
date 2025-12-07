class UsersController < ApplicationController
  require "nokogiri"
  skip_before_action :require_login, :require_authentication, only: [ :new, :create ], raise: false

  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_self_or_admin, only: [ :show, :edit, :update, :destroy ]

  def index
    # Optional: global user list (you can lock this down to admins later if you want)
    @users = User.order(created_at: :desc)

    # Only chore groups where the *current_user* is an active member (removed_at is nil)
    active_groups =
      ChoreGroup
        .joins(:members)
        .where(members: { user_id: current_user.id, removed_at: nil })
        .distinct
        .order(created_at: :desc)

    @pagy, @chore_groups = pagy(:offset, active_groups, limit: 5)
  end

  def show
    # Only the groups THIS user belongs to (you can mirror the same logic here if you want):
    # active_groups =
    #   ChoreGroup
    #     .joins(:members)
    #     .where(members: { user_id: @user.id, removed_at: nil })
    #     .distinct
    #     .order(created_at: :desc)
    # @pagy, @chore_groups = pagy(:offset, active_groups, limit: 5)
  end

  def new
    @user = User.new
    if current_user
      redirect_to users_path, alert: "You already have an account."
    end
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # Send the verification email
      UserMailer.verification(@user).deliver_later

      # Redirect to the sign-in page with a notice
      redirect_to new_session_path, notice: "User created. Please check your email to verify your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attrs = user_params
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank? && attrs[:password_confirmation].blank?

    if @user.update(attrs)
      redirect_to @user, notice: "User updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User deleted."
  end

  private

  def ensure_self_or_admin
    # adjust the admin check to your app (e.g., current_user.admin?)
    redirect_to root_path, alert: "Not authorized." unless current_user == @user
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
