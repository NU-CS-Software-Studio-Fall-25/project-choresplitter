class AddAdminNameToChoreGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :chore_groups, :admin_name, :string
  end
end
