require "test_helper"

class ImageUploadTest < ActiveSupport::TestCase
  test "image with an allowed content type that vips can read is an image" do
    assert ImageUpload.image?(file_fixture("avatar.png").open, "avatar.png")
  end

  test "bytes named as an image that vips can't read are not an image" do
    assert_not ImageUpload.image?(file_fixture("not-an-image.png").open, "not-an-image.png")
    assert_not ImageUpload.image?(StringIO.new(""), "empty.png")
  end

  test "file that is not an image is not an image" do
    assert_not ImageUpload.image?(file_fixture("responsible_subject_emails/ivanka_expected.txt").open, "ivanka.txt")
  end

  test "image bytes without a path are readable" do
    assert ImageUpload.readable?(StringIO.new(file_fixture("avatar.png").binread))
  end

  test "io is rewound after the checks" do
    io = StringIO.new(file_fixture("avatar.png").binread)
    ImageUpload.image?(io, "avatar.png")

    assert_equal 0, io.pos
  end

  test "heic photo is converted to jpeg" do
    heic = uploaded_file("photo.heic", "image/heic")
    skip "vips here can't decode HEIC" unless ImageUpload.readable?(heic)

    jpeg = ImageUpload.normalize(heic)

    assert_equal "photo.jpg", jpeg.original_filename
    assert_equal "image/jpeg", jpeg.content_type
    assert_equal "image/jpeg", Marcel::MimeType.for(jpeg)
  end

  test "other files are not converted" do
    png = uploaded_file("avatar.png", "image/png")
    junk = uploaded_file("not-an-image.png", "image/png")

    assert_same png, ImageUpload.normalize(png)
    assert_same junk, ImageUpload.normalize(junk)
  end

  test "attachable keeps a readable image as it is" do
    attachable = ImageUpload.attachable(file_fixture("avatar.png").open, "avatar.png")

    assert_nil attachable[:content_type]
  end

  test "attachable stores bytes named as an image that vips can't read as a plain file" do
    attachable = ImageUpload.attachable(file_fixture("not-an-image.png").open, "scan.png")

    assert_equal "application/octet-stream", attachable[:content_type]
    assert_equal false, attachable[:identify]
  end

  private

  def uploaded_file(name, type)
    Rack::Test::UploadedFile.new(file_fixture(name), type)
  end
end
