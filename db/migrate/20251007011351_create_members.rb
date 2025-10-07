class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.string :role
      t.integer :points

      t.timestamps
    end
  end
end
