require "test_helper"

class ImageFileTest < ActiveSupport::TestCase
  test "image file is readable" do
    assert ImageFile.readable?(file_fixture("avatar.png").open)
  end

  test "image bytes without a path are readable" do
    assert ImageFile.readable?(StringIO.new(file_fixture("avatar.png").binread))
  end

  test "empty or unknown bytes are not readable" do
    assert_not ImageFile.readable?(StringIO.new(""))
    assert_not ImageFile.readable?(file_fixture("not-an-image.png").open)
  end

  test "io is rewound after the check" do
    io = StringIO.new(file_fixture("avatar.png").binread)
    ImageFile.readable?(io)

    assert_equal 0, io.pos
  end
end
