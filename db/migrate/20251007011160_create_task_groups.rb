class CreateTaskGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :task_groups do |t|
      t.references :chore_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
