FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }

    # Generate a valid password matching PASSWORD_REQUIREMENTS
    password_digest { BCrypt::Password.create("TestPass1!") }

    # Optional: override password_digest to test raw password validations
    transient do
      raw_password { "TestPass1!" }
    end
  end
end
