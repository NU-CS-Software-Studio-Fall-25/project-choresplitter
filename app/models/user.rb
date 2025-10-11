class User < ApplicationRecord
  has_secure_password
  
  has_many :members, dependent: :destroy
  has_many :chore_groups, through: :members

  has_many :assigned_tasks, class_name: "Task", foreign_key: "assignee_id"
  has_many :tasks, through: :chore_groups
end
