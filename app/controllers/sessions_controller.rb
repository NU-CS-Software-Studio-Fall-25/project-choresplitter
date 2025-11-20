class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  skip_before_action :require_login, :require_authentication, only: [ :new, :create ], raise: false
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
      if user.email_verified? # <-- CHECK VERIFICATION
        reset_session          
        session[:user_id] = user.id
        start_new_session_for(user)  
        redirect_to users_path, notice: "Signed in!"
      else
        # Password is correct, but email is not verified
        flash.now[:alert] = "You must verify your email address before signing in. Please check your inbox."
        render :new, status: :unprocessable_entity
      end
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
    Current.session&.destroy if Current.respond_to?(:session)
    cookies.delete(:session_token) # or whatever cookie you set in start_new_session_for
    # clear request-local Current
    Current.user = nil if defined?(Current)
    Current.session = nil if defined?(Current) && Current.respond_to?(:session)
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
    [ email, password ]
  end
end
