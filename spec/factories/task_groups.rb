FactoryBot.define do
  factory :task_group do
    association :chore_group
  end
end
