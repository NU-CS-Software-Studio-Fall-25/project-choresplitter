class Task < ApplicationRecord
  belongs_to :task_group
  belongs_to :member, optional: true

  # state management and validation
  STATES = %w[open completed].freeze

  validates :state, inclusion: { in: STATES }

  validates :title, presence: true

  # helper funcs
  def overdue?
    due_date.present? && due_date < Time.zone.now && state != "completed"
  end

  def complete!
    update!(state: "completed",  completed_at: Time.zone.now)
  end

  def reopen!
    update!(state: "open", completed_at: nil)
  end

  def open?
    state == "open"
  end

  def completed?
    state == "completed"
  end
end
