class ApplicationController < ActionController::Base
  include Authentication
  before_action :set_current_user
  helper_method :current_user, :user_signed_in?

  private

  def set_current_user
    Current.user = @current_user = User.find_by(id: session[:user_id])
  end

  def current_user = @current_user

  def user_signed_in?
    current_user.present?
  end
  allow_browser versions: :modern
end
