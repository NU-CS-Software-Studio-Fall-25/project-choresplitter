require "rails_helper"

RSpec.describe Bill, type: :model do
  let(:user) do
    User.create!(
      email_address: "test@example.com",
      password: "Password!"
    )
  end

  let(:chore_group) do
    group = ChoreGroup.new(
      name: "Test Group",
      code: "ABCDE" # must be 5 characters and valid format
    )
    group.admin = user
    group.save!
    group
  end

  let(:member) do
    Member.create!(
      user: user,
      chore_group: chore_group,
      role: "admin"
    )
  end

  describe "validations" do
    it "is valid with non-negative total_amount and description" do
      bill = Bill.new(
        chore_group: chore_group,
        member: member,
        total_amount: 100.0,
        description: "Groceries"
      )

      expect(bill).to be_valid
    end

    it "is invalid with negative total_amount" do
      bill = Bill.new(
        chore_group: chore_group,
        member: member,
        total_amount: -1,
        description: "Groceries"
      )

      expect(bill).not_to be_valid
      expect(bill.errors[:total_amount]).to be_present
    end

    it "is invalid without a description" do
      bill = Bill.new(
        chore_group: chore_group,
        member: member,
        total_amount: 50.0,
        description: nil
      )

      expect(bill).not_to be_valid
      expect(bill.errors[:description]).to be_present
    end
  end
end
