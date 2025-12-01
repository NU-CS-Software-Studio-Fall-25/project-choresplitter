class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.references :chore_group, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"  # pending / accepted / declined

      t.timestamps
    end

    add_index :invitations, [ :chore_group_id, :recipient_id, :status ],
              name: "index_invitations_on_group_recipient_status"
  end
end
