require "application_system_test_case"

class BillSharesTest < ApplicationSystemTestCase
  setup do
    @bill_share = bill_shares(:one)
  end

  test "visiting the index" do
    visit bill_shares_url
    assert_selector "h1", text: "Bill shares"
  end

  test "should create bill share" do
    visit bill_shares_url
    click_on "New bill share"

    fill_in "Amount", with: @bill_share.amount
    fill_in "Bill", with: @bill_share.bill_id
    fill_in "Member", with: @bill_share.member_id
    fill_in "Status", with: @bill_share.status
    click_on "Create Bill share"

    assert_text "Bill share was successfully created"
    click_on "Back"
  end

  test "should update Bill share" do
    visit bill_share_url(@bill_share)
    click_on "Edit this bill share", match: :first

    fill_in "Amount", with: @bill_share.amount
    fill_in "Bill", with: @bill_share.bill_id
    fill_in "Member", with: @bill_share.member_id
    fill_in "Status", with: @bill_share.status
    click_on "Update Bill share"

    assert_text "Bill share was successfully updated"
    click_on "Back"
  end

  test "should destroy Bill share" do
    visit bill_share_url(@bill_share)
    click_on "Destroy this bill share", match: :first

    assert_text "Bill share was successfully destroyed"
  end
end
