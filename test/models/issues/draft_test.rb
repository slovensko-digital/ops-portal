require "test_helper"

class Issues::DraftTest < ActiveSupport::TestCase
  test "load_geo_from_exif does not set coordinates when GPS contains NaN values" do
    user = users(:one)
    draft = Issues::Draft.create!(author: user)

    # Attach a fake photo
    draft.photos.attach(io: StringIO.new("fake image"), filename: "photo.jpg", content_type: "image/jpeg")
    photo = draft.photos.first

    # Mock Exif::Data to return GPS with NaN values (Android empty GPS edge case)
    exif_data_mock = Minitest::Mock.new
    gps_data = {
      gps_latitude: [ Float::NAN, Float::NAN, Float::NAN ],
      gps_longitude: [ Float::NAN, Float::NAN, Float::NAN ]
    }
    exif_data_mock.expect(:[], gps_data, [ :gps ])

    Exif::Data.stub :new, exif_data_mock do
      draft.load_geo_from_exif(photo)
    end

    assert_nil draft.latitude, "Latitude should not be set when GPS contains NaN"
    assert_nil draft.longitude, "Longitude should not be set when GPS contains NaN"
    assert_not draft.latlon_from_exif

    exif_data_mock.verify
  end

  test "checks step does not pass when checks were never computed" do
    draft = Issues::Draft.create!(author: users(:one), duplicates_shown: true)
    draft.checks = nil

    assert_not draft.valid?(:checks_step)
    assert draft.errors.added?(:checks, :invalid)
  end

  test "checks step passes with an empty checks array" do
    draft = Issues::Draft.create!(author: users(:one), duplicates_shown: true)
    draft.checks = []

    assert draft.valid?(:checks_step)
  end

  test "not confirmable when checks were never computed" do
    draft = Issues::Draft.create!(author: users(:one))
    draft.checks = nil

    assert_not draft.confirmable?
  end

  test "confirmable when all checks allow confirmation" do
    draft = Issues::Draft.create!(author: users(:one))
    draft.checks = [ { "action" => "confirm" } ]

    assert draft.confirmable?
  end

  test "first unfinished step follows the wizard order" do
    draft = Issues::Draft.new(author: users(:one))
    assert_equal :photos, draft.first_unfinished_step

    draft.photos.attach(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg", content_type: "image/jpeg")
    assert_equal :geo, draft.first_unfinished_step

    draft.assign_attributes(latitude: 48.16, longitude: 17.05)
    assert_equal :suggestions, draft.first_unfinished_step

    draft.picked_suggestion_index = -1
    assert_equal :category, draft.first_unfinished_step

    draft.category = issues_categories(:one)
    assert_equal :details, draft.first_unfinished_step

    draft.assign_attributes(title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit")
    assert_equal :summary, draft.first_unfinished_step
    assert draft.complete?
  end

  test "first unfinished step is the category when a picked suggestion's category does not exist" do
    draft = Issues::Draft.new(
      author: users(:one), latitude: 48.16, longitude: 17.05, picked_suggestion_index: 0,
      title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit"
    )
    draft.photos.attach(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg", content_type: "image/jpeg")

    assert_equal :category, draft.first_unfinished_step
  end

  test "first unfinished step is the category when the author wrote a title without picking a suggestion" do
    draft = Issues::Draft.new(
      author: users(:one), latitude: 48.16, longitude: 17.05,
      title: "Graffiti na skrini", description: "Je tu graffiti, treba vycistit"
    )
    draft.photos.attach(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg", content_type: "image/jpeg")

    assert_equal :category, draft.first_unfinished_step
  end
end
