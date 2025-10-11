class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description

      # foreign key to members
      t.references :member, null: false, foreign_key: true

      # foreign key to task_groups
      t.references :task_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
