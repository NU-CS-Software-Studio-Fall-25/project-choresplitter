class TaskGroup < ApplicationRecord
  belongs_to :chore_group
  has_many :tasks, dependent: :destroy
end
