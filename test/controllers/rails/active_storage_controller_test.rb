require "test_helper"

class Rails::ActiveStorageControllerTest < ActionDispatch::IntegrationTest
  test "direct uploads are not available" do
    post "/rails/active_storage/direct_uploads", params: {
      blob: { filename: "avatar.png", byte_size: 6120, checksum: "WcQEIzRIcPLQrnYirn6GFQ==", content_type: "image/png" }
    }, as: :json

    assert_response :not_found
    assert_equal 0, ActiveStorage::Blob.where(filename: "avatar.png").count
  end

  test "variant of a blob that is not an image responds with unprocessable entity" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("MATLAB 5.0 MAT-file, Platform: k" + "\0" * 200),
      filename: "avatar.png",
      content_type: "image/png",
      identify: false
    )

    get rails_representation_path(blob.variant(resize_to_fill: [ 360, 360 ]), only_path: true)

    assert_response :unprocessable_entity
  end

  test "variant of an image is still served" do
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("avatar.png").open,
      filename: "photo.png"
    )

    get rails_representation_path(blob.variant(resize_to_fill: [ 360, 360 ]), only_path: true)

    assert_response :redirect
  end
end
