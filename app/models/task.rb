class Task < ApplicationRecord
  belongs_to :task_group
  belongs_to :assignee, class_name: "User"

  validates :title, presence: true
end
