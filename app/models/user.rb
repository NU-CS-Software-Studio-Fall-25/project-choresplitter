class User < ApplicationRecord
  has_secure_password
  has_secure_token :email_verification_token # Add this
  has_secure_token :password_reset_token

  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :members, dependent: :destroy
  has_many :chore_groups, through: :members

  # Define a regex for the special character and uppercase requirement
  PASSWORD_REQUIREMENTS = /\A
    (?=.{8,})           # Must be at least 8 characters long
    (?=.*[A-Z])         # Must contain at least one uppercase letter
    (?=.*[^A-Za-z0-9])  # Must contain at least one special character
  /x

  # Add the validation
  validates :password, 
    format: { 
      with: PASSWORD_REQUIREMENTS, 
      message: "must be at least 8 characters long and include one uppercase letter and one special character" 
    }, 
    if: -> { password.present? || password_confirmation.present? }

  def email_verified?
    email_verified_at.present?
  end
end
