class AddRemovedAtToMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :members, :removed_at, :datetime
    add_index  :members, :removed_at
  end
end