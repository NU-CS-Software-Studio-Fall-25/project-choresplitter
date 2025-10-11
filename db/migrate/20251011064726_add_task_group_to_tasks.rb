class AddTaskGroupToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :task_group, null: false, foreign_key: true
  end
end
