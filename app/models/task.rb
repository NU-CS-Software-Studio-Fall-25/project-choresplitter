class Task < ApplicationRecord
  belongs_to :task_group
  belongs_to :member, optional: true

  validates :title, presence: true
end
