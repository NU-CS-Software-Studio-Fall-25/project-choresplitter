class OmniauthCallbacksController < ApplicationController
  # Skip authentication checks for the callback
  skip_before_action :require_login, :require_authentication, raise: false

  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user.persisted?
      reset_session
      session[:user_id] = user.id
      start_new_session_for(user) if defined?(start_new_session_for) # Use your helper if it exists
      redirect_to users_path, notice: "Successfully signed in with Google!"
    else
      redirect_to new_session_path, alert: "Authentication failed, please try again."
    end
  end

  def failure
    redirect_to new_session_path, alert: "Authentication failed."
  end
end
