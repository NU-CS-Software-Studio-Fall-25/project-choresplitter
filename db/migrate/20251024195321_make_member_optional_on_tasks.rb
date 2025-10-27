# db/migrate/xxxxxxxxxxxxxx_make_member_optional_on_tasks.rb
class MakeMemberOptionalOnTasks < ActiveRecord::Migration[7.1]
  def up
    change_column_null :tasks, :member_id, true
    # If you added a FK constraint earlier, consider allowing nulls and (optionally) nullify on delete:
    # remove_foreign_key :tasks, :members
    # add_foreign_key :tasks, :members, on_delete: :nullify
  end

  def down
    # Optional: going back to NOT NULL will fail if nulls exist; you’d need to handle them first.
    change_column_null :tasks, :member_id, false
  end
end
