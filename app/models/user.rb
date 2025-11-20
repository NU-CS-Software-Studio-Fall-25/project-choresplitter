class User < ApplicationRecord
  has_secure_password
  has_secure_token :email_verification_token # Add this
  has_secure_token :password_reset_token

  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :members, dependent: :destroy
  has_many :chore_groups, through: :members

  def self.from_omniauth(auth)
    # 1. Check if user exists by unique UID and Provider
    user = find_by(uid: auth.uid, provider: auth.provider)
    return user if user

    # 2. If not, check if user exists by Email (link accounts)
    user = find_by(email_address: auth.info.email)
    if user
      user.update(uid: auth.uid, provider: auth.provider)
      # If linking, assume Google has verified the email
      user.update(email_verified_at: Time.current) unless user.email_verified?
      return user
    end

    # 3. If neither, create a new user
    create do |u|
      u.email_address = auth.info.email
      u.uid = auth.uid
      u.provider = auth.provider
      u.password = SecureRandom.hex(15) # Generate random password
      u.email_verified_at = Time.current # Google emails are verified
    end
  end
  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :sender_id,
           dependent: :nullify

  has_many :received_invitations,
           class_name: "Invitation",
           foreign_key: :recipient_id,
           dependent: :destroy

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
