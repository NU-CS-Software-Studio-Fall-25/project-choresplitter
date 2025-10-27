require "test_helper"

class TaskGroupsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get task_groups_show_url
    assert_response :success
  end
end
