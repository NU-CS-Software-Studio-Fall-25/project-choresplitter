class RemoveTaskIdFromMembers < ActiveRecord::Migration[8.0]
  def change
    remove_column :members, :task_id, :integer
  end
end
