class CreateBillShares < ActiveRecord::Migration[7.0]
  def change
    create_table :bill_shares do |t|
      t.references :bill, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "unpaid"

      t.timestamps
    end
  end
end
