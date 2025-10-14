class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  # rate_limit to: 10, within: 3.minutes, only: :create,
  #          with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new; end

  def create
    email, password = extract_credentials

    if email.blank? || password.blank?
      flash.now[:alert] = "Email and password are required."
      return render :new, status: :unprocessable_entity
    end

    user = User.find_by(email_address: email)

    if user&.authenticate(password) # requires has_secure_password + password_digest
      reset_session               # prevents session fixation
      session[:user_id] = user.id
      redirect_to users_path, notice: "Signed in!"
    else
      flash.now[:alert] = "Try another email address or password."
      render :new, status: :unprocessable_entity
    end
  rescue ArgumentError => e
    # e.g. "You must have a password_digest column ..." if has_secure_password is misconfigured
    Rails.logger.error("Auth error: #{e.class}: #{e.message}")
    flash.now[:alert] = "Sign-in is temporarily unavailable. Please try again soon."
    render :new, status: :internal_server_error
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end

  private

  def extract_credentials
    creds =
      if params.key?(:session)
        params.require(:session).permit(:email, :email_address, :password)
      else
        params.permit(:email, :email_address, :password)
      end

    email = (creds[:email_address] || creds[:email]).to_s.strip.downcase
    password = creds[:password].to_s
    [email, password]
  end
end
