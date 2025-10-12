class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description

      # IDs only for now (avoid FK at create time)
      t.bigint :member_id, null: false
      t.bigint :task_group_id, null: false

      t.timestamps
    end

    add_index :tasks, :member_id
    add_index :tasks, :task_group_id
  end
end
