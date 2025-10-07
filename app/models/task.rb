class Task < ApplicationRecord
  belongs_to :assignee, class_name: "User"

  has_many :members, dependent: :destroy
  has_many :users, through: :members
end
