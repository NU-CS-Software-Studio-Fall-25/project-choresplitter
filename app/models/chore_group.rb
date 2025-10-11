class ChoreGroup < ApplicationRecord
  belongs_to :admin, class_name: "User"

  has_many :members, dependent: :destroy
  has_many :users, through: :members

  has_many :task_groups, dependent: :destroy
  has_many :tasks, through: :task_groups
end
