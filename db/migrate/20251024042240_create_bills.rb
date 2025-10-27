class CreateBills < ActiveRecord::Migration[7.0]
  def change
    create_table :bills do |t|
      t.references :chore_group, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.string :description, null: false

      t.timestamps
    end
  end
end
