FactoryBot.define do
  factory :chore_group do
    sequence(:name) { |n| "Chore Group #{n}" }
    association :admin, factory: :user, strategy: :build
    admin_name { admin.email_address }
    sequence(:code) { |n| "%05d" % n }
  end
end
