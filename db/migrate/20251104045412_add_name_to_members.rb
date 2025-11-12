class AddNameToMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :name, :string, limit: 100  # remove limit if you don't want one
    # add_index :members, :name  # usually not needed; uncomment only if you’ll search by name a lot
  end
end
