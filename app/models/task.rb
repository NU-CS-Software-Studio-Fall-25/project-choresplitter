class Task < ApplicationRecord
  belongs_to :task_group
  belongs_to :member

  validates :title, presence: true
end
