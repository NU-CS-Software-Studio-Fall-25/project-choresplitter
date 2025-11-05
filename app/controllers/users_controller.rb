class UsersController < ApplicationController
  require "nokogiri"
  skip_before_action :require_login, :require_authentication, only: [ :new, :create ], raise: false

  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_self_or_admin, only: [ :show, :edit, :update, :destroy ]

  def index
    # Consider restricting to admins if you don’t want a public user list:
    @users = User.order(created_at: :desc)
    @pagy, @chore_groups = pagy(:offset, current_user.chore_groups, limit: 5)
  end

  def show
    # Only the groups THIS user belongs to
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: "User created."
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

  # def require_login
  #   redirect_to new_session_path, alert: "Please sign in first." unless user_signed_in?
  # end

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
