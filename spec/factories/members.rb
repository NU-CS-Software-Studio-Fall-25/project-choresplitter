FactoryBot.define do
  factory :member do
    association :user
    association :chore_group
    role { "member" }
    points { 0 }
    sequence(:name) { |n| "Member #{n}" }
  end
end
