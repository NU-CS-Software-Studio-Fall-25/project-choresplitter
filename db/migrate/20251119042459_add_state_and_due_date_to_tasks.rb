class AddStateAndDueDateToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :state, :string, null: false, default: "pending"
    add_column :tasks, :due_date, :datetime
  end
end
