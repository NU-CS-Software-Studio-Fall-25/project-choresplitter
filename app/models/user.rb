class User < ApplicationRecord
  has_secure_password
  has_secure_token :email_verification_token
  has_secure_token :password_reset_token

  has_many :sessions, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :chore_groups, through: :members

  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :sender_id,
           dependent: :nullify

  has_many :received_invitations,
           class_name: "Invitation",
           foreign_key: :recipient_id,
           dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

 # Define a regex for the special character and uppercase requirement
 PASSWORD_REQUIREMENTS = /\A(?=.{8,})(?=.*[A-Z])(?=.*[^A-Za-z0-9]).*\z/x

validates :password,
  format: {
    with: PASSWORD_REQUIREMENTS,
    message: "must be at least 8 characters long and include one uppercase letter and one special character"
  },
  if: -> { password.present? }


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

      # FIX: Generate a password that meets the Regex requirements
      # Hex provides length/numbers. "A!" provides the Uppercase and Special Char.
      generated_password = SecureRandom.hex(10) + "A!"

      u.password = generated_password
      u.password_confirmation = generated_password

      u.email_verified_at = Time.current
    end
  end

  def email_verified?
    email_verified_at.present?
  end
end
