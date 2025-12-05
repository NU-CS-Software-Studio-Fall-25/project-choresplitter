class AddDefaultToMembersPoints < ActiveRecord::Migration[8.0]
  def up
    # Set DB default
    change_column_default :members, :points, from: nil, to: 0

    # Backfill existing rows
    Member.where(points: nil).update_all(points: 0)

    # Make it NOT NULL
    change_column_null :members, :points, false
  end

  def down
    change_column_null :members, :points, true
    change_column_default :members, :points, from: 0, to: nil
  end
end
