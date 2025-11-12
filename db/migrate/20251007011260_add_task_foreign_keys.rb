class AddTaskForeignKeys < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :tasks, :members,     column: :member_id
    add_foreign_key :tasks, :task_groups, column: :task_group_id
  end
end
