class UsersController < ApplicationController
  require "nokogiri"
  skip_before_action :require_login, :require_authentication, only: [ :new, :create ], raise: false

  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :ensure_self_or_admin, only: [ :show, :edit, :update, :destroy ]

  def index
    @users = User.order(created_at: :desc)
    @pagy, @chore_groups = pagy(:offset, current_user.chore_groups, limit: 5)
  end

  def show
    # Only the groups THIS user belongs to
  end

  def new
    @user = User.new
    if current_user
      redirect_to users_path, alert: "You already have an account."
    end
  end

  def create
    @user = User.new(user_params)

    # Normalize email for comparison (in case-insensitive way)
    email = @user.email_address.to_s.strip.downcase

    if User.where("LOWER(email_address) = ?", email).exists?
      # Don’t even try to save; show nice error instead of 500
      @user.errors.add(:email_address, "has already been taken")
      flash.now[:alert] = "That email is already in use. Please sign in or use a different email."
      return render :new, status: :unprocessable_entity
    end

    # Try to save normally, but still guard against DB race (RecordNotUnique)
    if @user.save
      UserMailer.verification(@user).deliver_later
      redirect_to new_session_path, notice: "User created. Please check your email to verify your account."
    else
      flash.now[:alert] ||= @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # Fallback in case two signups race or validation missed something
    @user.errors.add(:email_address, "has already been taken")
    flash.now[:alert] = "That email is already in use. Please sign in or use a different email."
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    attrs = user_params
    if attrs[:password].blank? && attrs[:password_confirmation].blank?
      attrs = attrs.except(:password, :password_confirmation)
    end

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
    redirect_to root_path, alert: "Not authorized." unless current_user == @user
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
