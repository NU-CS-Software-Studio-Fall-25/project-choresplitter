class AddPointValueToTasks < ActiveRecord::Migration[8.0]
  def up
    add_column :tasks, :point_value, :integer, default: 10, null: false

    # Optional: if you already have tasks and want them all to start at 10
    Task.reset_column_information
    Task.where(point_value: nil).update_all(point_value: 10)
  end

  def down
    remove_column :tasks, :point_value
  end
end
