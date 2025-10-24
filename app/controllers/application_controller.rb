class ApplicationController < ActionController::Base
  # include Authentication
  #
  before_action :set_current_user
  before_action :require_login
  helper_method :current_user, :user_signed_in?

  private

  def set_current_user
    Current.user = Current.session&.user
  end

  def current_user = Current.user

  def user_signed_in?
    Current.user.present?
  end

  def require_login
    unless user_signed_in?
      redirect_to new_session_path, alert: "Please sign in first."
    end
  end
  allow_browser versions: :modern
end
