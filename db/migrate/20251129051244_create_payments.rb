class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :chore_group, null: false, foreign_key: true
      t.references :payer, null: false, foreign_key: { to_table: :members }
      t.references :payee, null: false, foreign_key: { to_table: :members }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :date, default: -> { 'CURRENT_DATE' }
      t.string :description

      t.timestamps
    end
  end
end
