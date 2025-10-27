class ChoreGroup < ApplicationRecord
  belongs_to :admin, class_name: "User"

  has_many :members, dependent: :destroy
  has_many :users, through: :members

  has_many :task_groups, dependent: :destroy
  has_many :tasks, through: :task_groups

  has_many :bill, dependent: :destroy
  has_many :bill_share, through: :bill
end
