require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "failed profile update does not persist preferred places" do
    user = users(:one)
    post "/login", params: { email: user.email, password: "password" }
    assert_response :redirect

    nitra = municipalities(:Nitra)
    assert_not_includes user.reload.municipalities.pluck(:id), nitra.id

    patch profile_path, params: { user: { name: "", municipality_ids: [ "", nitra.id ] } }
    assert_response :unprocessable_entity

    assert_not_includes user.reload.municipalities.pluck(:id), nitra.id
  end
end
