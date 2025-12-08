FactoryBot.define do
  factory :task do
    title { "Sample Task" }
    description { "Task description" }
    association :task_group
    association :member
    state { "open" }
    point_value { 10 }
  end
end
