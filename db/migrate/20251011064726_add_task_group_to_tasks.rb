class AddTaskGroupToTasks < ActiveRecord::Migration[8.0]
  # use lightweight AR classes inside the migration
  class ChoreGroup < ApplicationRecord
    self.table_name = "chore_groups"
  end

  class TaskGroup < ApplicationRecord
    self.table_name = "task_groups"
  end

  class Task < ApplicationRecord
    self.table_name = "tasks"
  end

  def up
    # 1) Add the column as nullable so the schema change can apply
    add_reference :tasks, :task_group, foreign_key: true, null: true unless column_exists?(:tasks, :task_group_id)

    # 2) Backfill for existing tasks
    # Create a default ChoreGroup and TaskGroup, then assign all existing tasks to it
    default_cg = ChoreGroup.create!(name: "Default Group") unless ChoreGroup.exists?(name: "Default Group")
    default_cg ||= ChoreGroup.find_by!(name: "Default Group")

    default_tg = TaskGroup.create!(chore_group_id: default_cg.id) unless TaskGroup.exists?(chore_group_id: default_cg.id)
    default_tg ||= TaskGroup.find_by!(chore_group_id: default_cg.id)

    Task.where(task_group_id: nil).update_all(task_group_id: default_tg.id)

    # 3) Now enforce NOT NULL
    change_column_null :tasks, :task_group_id, false
  end

  def down
    # Drop the reference
    remove_reference :tasks, :task_group, foreign_key: true if column_exists?(:tasks, :task_group_id)
  end
end
