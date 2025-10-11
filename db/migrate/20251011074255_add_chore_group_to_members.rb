class AddChoreGroupToMembers < ActiveRecord::Migration[8.0]
  def change
    add_reference :members, :chore_group, null: false, foreign_key: true
  end
end
