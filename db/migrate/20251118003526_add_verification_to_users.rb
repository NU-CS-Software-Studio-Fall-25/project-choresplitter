# db/migrate/xxxxxxxx_add_verification_to_users.rb
class AddVerificationToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :email_verified_at, :datetime
    add_column :users, :email_verification_token, :string
    
    # Add this line for a unique index, which also makes lookups faster
    add_index :users, :email_verification_token, unique: true
  end
end