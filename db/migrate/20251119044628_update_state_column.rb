class UpdateStateColumn < ActiveRecord::Migration[8.0]
  def change
    change_column_default :tasks, :state, "open"
  end
end
