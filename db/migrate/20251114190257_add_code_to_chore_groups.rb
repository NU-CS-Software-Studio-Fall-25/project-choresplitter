class AddCodeToChoreGroups < ActiveRecord::Migration[8.0]
  def up
    add_column :chore_groups, :code, :string, limit: 5
    add_index  :chore_groups, :code, unique: true

    # backfill existing rows
    say_with_time "Backfilling chore_group codes" do
      ChoreGroup.reset_column_information
      ChoreGroup.find_each do |cg|
        next if cg.code.present?
        cg.update_columns(code: generate_unique_code) # skip validations/callbacks
      end
    end

    # If your DB supports it, you can enforce NOT NULL:
    # change_column_null :chore_groups, :code, false
  end

  def down
    remove_index  :chore_groups, :code
    remove_column :chore_groups, :code
  end

  private

  def generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(5)
      break code unless ChoreGroup.exists?(code: code)
    end
  end
end
