class User < ApplicationRecord
  has_secure_password

  has_many :members, dependent: :destroy
  has_many :tasks, through: :members

  has_many :assigned_tasks, class_name: "Task", foreign_key: "assignee_id"
end
