class CreateChoreGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :chore_groups do |t|
      t.string :name
      t.integer :admin_id

      t.timestamps
    end
    add_index :chore_groups, :admin_id
  end
end
