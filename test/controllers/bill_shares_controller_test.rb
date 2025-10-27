require "test_helper"

class BillSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bill_share = bill_shares(:one)
  end

  test "should get index" do
    get bill_shares_url
    assert_response :success
  end

  test "should get new" do
    get new_bill_share_url
    assert_response :success
  end

  test "should create bill_share" do
    assert_difference("BillShare.count") do
      post bill_shares_url, params: { bill_share: { amount: @bill_share.amount, bill_id: @bill_share.bill_id, member_id: @bill_share.member_id, status: @bill_share.status } }
    end

    assert_redirected_to bill_share_url(BillShare.last)
  end

  test "should show bill_share" do
    get bill_share_url(@bill_share)
    assert_response :success
  end

  test "should get edit" do
    get edit_bill_share_url(@bill_share)
    assert_response :success
  end

  test "should update bill_share" do
    patch bill_share_url(@bill_share), params: { bill_share: { amount: @bill_share.amount, bill_id: @bill_share.bill_id, member_id: @bill_share.member_id, status: @bill_share.status } }
    assert_redirected_to bill_share_url(@bill_share)
  end

  test "should destroy bill_share" do
    assert_difference("BillShare.count", -1) do
      delete bill_share_url(@bill_share)
    end

    assert_redirected_to bill_shares_url
  end
end
