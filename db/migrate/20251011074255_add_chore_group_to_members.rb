class AddChoreGroupToMembers < ActiveRecord::Migration[8.0]
  # lightweight AR classes for use inside the migration
  class ChoreGroup < ApplicationRecord
    self.table_name = "chore_groups"
  end

  class Member < ApplicationRecord
    self.table_name = "members"
  end

  def up
    # 1) Add as NULLable first
    add_reference :members, :chore_group, foreign_key: true, null: true unless column_exists?(:members, :chore_group_id)

    # 2) Backfill existing members to a default chore group
    default_group = ChoreGroup.find_or_create_by!(name: "Default Group")
    Member.where(chore_group_id: nil).update_all(chore_group_id: default_group.id)

    # 3) Now enforce NOT NULL
    change_column_null :members, :chore_group_id, false
  end

  def down
    remove_reference :members, :chore_group, foreign_key: true if column_exists?(:members, :chore_group_id)
  end
end
