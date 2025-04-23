require "test_helper"

class LookupsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get lookups_index_url
    assert_response :success
  end

  test "should get upload" do
    get lookups_upload_url
    assert_response :success
  end

  test "should get process" do
    get lookups_process_url
    assert_response :success
  end

  test "should get download" do
    get lookups_download_url
    assert_response :success
  end
end
