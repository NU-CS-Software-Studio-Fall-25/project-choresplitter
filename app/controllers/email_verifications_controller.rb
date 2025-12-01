# app/controllers/email_verifications_controller.rb
class EmailVerificationsController < ApplicationController
    # Add this line
    # This skips BOTH filters
    skip_before_action :require_login, :require_authentication, only: [ :edit ], raise: false

  def edit
    user = User.find_by(email_verification_token: params[:token])

    if user
      # ... rest of your code ...
      user.update!(email_verified_at: Time.current)
      session[:user_id] = user.id
      redirect_to users_path, notice: "Email successfully verified. You are now signed in!"
    else
      redirect_to new_session_path, alert: "Invalid or expired verification link."
    end
  end
end
