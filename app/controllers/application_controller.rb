class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers su
  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])   # or your helper
  end

  def user_signed_in?
    current_user.present?
  end
  allow_browser versions: :modern
end
