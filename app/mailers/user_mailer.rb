# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  default from: 'notifications@example.com' # Change this

  def verification(user)
    @user = user
    @verification_url = email_verification_url(token: @user.email_verification_token)
    
    mail(to: @user.email_address, subject: 'Verify your email address')
  end
end