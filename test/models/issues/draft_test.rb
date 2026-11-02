require "test_helper"

class Issues::DraftTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @gemini_api_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key"
  end

  teardown do
    ENV["GEMINI_API_KEY"] = @gemini_api_key
  end

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

  test "similar_around returns nearby issues of the same category regardless of subcategory" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    issue.update_columns(subcategory_id: nil)

    assert_includes draft.similar_around, issue
  end

  test "similar_around ignores issues farther than 500 meters" do
    draft = draft_near(issues(:sent_to_responsible), latitude_offset: 0.01)

    assert_not_includes draft.similar_around, issues(:sent_to_responsible)
  end

  test "similar_around uses the distance from DRAFT_DUPLICATES_DISTANCE" do
    draft = draft_near(issues(:sent_to_responsible), latitude_offset: 0.001)
    assert_includes draft.similar_around, issues(:sent_to_responsible)

    ENV["DRAFT_DUPLICATES_DISTANCE"] = "50"
    assert_not_includes draft.similar_around, issues(:sent_to_responsible)
  ensure
    ENV.delete("DRAFT_DUPLICATES_DISTANCE")
  end

  test "similar_around ignores issues of another category" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    issue.update_columns(category_id: nil)

    assert_not_includes draft.similar_around, issue
  end

  test "similar_around ignores issues that cannot be updated" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    issue.update_columns(resolution_external_id: nil)

    assert_not_includes draft.similar_around, issue
  end

  test "last_duplicates returns the stored duplicates that still accept updates" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    draft.last_duplicate_ids = [ issue.id ]

    assert_equal [ issue ], draft.last_duplicates.to_a

    issue.update_columns(discussion_closed: true)
    assert_empty draft.last_duplicates
  end

  test "last_duplicates returns the nearest stored duplicates up to the configured limit" do
    nearest = issues(:sent_to_responsible)
    farther = issues(:two)
    draft = draft_near(nearest)
    farther.update_columns(latitude: 48.1642, longitude: 17.0494)
    draft.last_duplicate_ids = [ farther.id, nearest.id ]

    assert_equal [ nearest, farther ], draft.last_duplicates.to_a

    ENV["DRAFT_DUPLICATES_LIMIT"] = "1"
    assert_equal [ nearest ], draft.last_duplicates.to_a
  ensure
    ENV.delete("DRAFT_DUPLICATES_LIMIT")
  end

  test "duplicates_nearby validation uses the stored duplicates and is skipped once they were shown" do
    draft = draft_near(issues(:sent_to_responsible))

    draft.last_duplicate_ids = []
    draft.valid?(:checks_step)
    assert_not draft.errors.added?(:base, :duplicates_nearby)

    draft.last_duplicate_ids = [ issues(:sent_to_responsible).id ]
    draft.valid?(:checks_step)
    assert draft.errors.added?(:base, :duplicates_nearby)

    draft.duplicates_shown = true
    draft.valid?(:checks_step)
    assert_not draft.errors.added?(:base, :duplicates_nearby)
  end

  test "duplicates_nearby validation passes when duplicates could not be detected" do
    draft = draft_near(issues(:sent_to_responsible))
    draft.last_duplicate_ids = nil

    draft.valid?(:checks_step)

    assert_not draft.errors.added?(:base, :duplicates_nearby)
  end

  test "stored duplicates and the decision to ignore them are reset when the location or category changes" do
    draft = draft_near(issues(:sent_to_responsible))
    draft.save!
    draft.update!(last_duplicate_ids: [ issues(:sent_to_responsible).id ], duplicates_shown: true)

    draft.update!(latitude: 48.1633)
    assert_nil draft.last_duplicate_ids
    assert_not draft.duplicates_shown

    draft.update!(last_duplicate_ids: [ issues(:sent_to_responsible).id ], duplicates_shown: true)
    draft.update!(category: nil)
    assert_nil draft.last_duplicate_ids
    assert_not draft.duplicates_shown
  end

  test "stored duplicates and the decision to ignore them survive changes unrelated to duplicates" do
    draft = draft_near(issues(:sent_to_responsible))
    draft.save!
    draft.update!(last_duplicate_ids: [ issues(:sent_to_responsible).id ], duplicates_shown: true)

    draft.update!(title: "Graffiti na skrini")

    assert_equal [ issues(:sent_to_responsible).id ], draft.last_duplicate_ids
    assert draft.duplicates_shown
  end

  test "similar_around ignores issues without a photo" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    issue.photos.detach

    assert_not_includes draft.similar_around, issue
  end

  test "reset_duplicates! clears the stored duplicates and the decision to ignore them" do
    draft = draft_near(issues(:sent_to_responsible))
    draft.save!
    draft.update!(last_duplicate_ids: [ issues(:sent_to_responsible).id ], duplicates_shown: true)

    draft.reset_duplicates!

    assert_nil draft.reload.last_duplicate_ids
    assert_not draft.duplicates_shown
  end

  test "detect_duplicates! stores the issues around whose photos Gemini marks as duplicates" do
    issue = issues(:sent_to_responsible)
    draft = draft_with_photo_near(issue)
    stub_gemini_duplicates([ issue.id, 999_999 ])

    draft.detect_duplicates!

    assert_equal [ issue.id ], draft.reload.last_duplicate_ids
    assert_requested :post, GEMINI_URL, body: /duplicates prompt/
    assert_requested :post, GEMINI_URL, body: /Existujúci podnet ID #{issue.id}/
  end

  test "detect_duplicates! stores no duplicates when Gemini finds none" do
    draft = draft_with_photo_near(issues(:sent_to_responsible))
    stub_gemini_duplicates([])

    draft.detect_duplicates!

    assert_equal [], draft.reload.last_duplicate_ids
  end

  test "detect_duplicates! does not ask Gemini when there are no issues around" do
    draft = draft_with_photo_near(issues(:sent_to_responsible), latitude_offset: 0.01)

    draft.detect_duplicates!

    assert_equal [], draft.reload.last_duplicate_ids
    assert_not_requested :post, GEMINI_URL
  end

  test "detect_duplicates! does not detect duplicates without a Gemini key" do
    draft = draft_with_photo_near(issues(:sent_to_responsible))
    ENV["GEMINI_API_KEY"] = ""

    draft.detect_duplicates!

    assert_equal [], draft.reload.last_duplicate_ids
    assert_not_requested :post, GEMINI_URL
  end

  test "detect_duplicates! leaves duplicates undetected when Gemini answers with an error" do
    draft = draft_with_photo_near(issues(:sent_to_responsible))
    stub_request(:post, GEMINI_URL).to_return(
      status: 404,
      headers: { "Content-Type" => "application/json" },
      body: { error: { code: 404, message: "Model not available", status: "NOT_FOUND" } }.to_json
    )

    draft.detect_duplicates!

    assert_nil draft.reload.last_duplicate_ids
  end

  test "detect_duplicates! leaves duplicates undetected when Gemini cannot be reached" do
    draft = draft_with_photo_near(issues(:sent_to_responsible))
    stub_request(:post, GEMINI_URL).to_timeout

    draft.detect_duplicates!

    assert_nil draft.last_duplicate_ids
    assert_nil draft.reload.last_duplicate_ids
  end

  test "submit_as_update_of adds an update to the issue and destroys the draft" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    draft.save!
    photo = ActiveStorage::Blob.create_and_upload!(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg")

    update = draft.submit_as_update_of(issue, text: "Stále tu je", attachments: [ photo.signed_id ])

    assert update.persisted?
    assert_equal issue, update.activity.issue
    assert_equal draft.author, update.author
    assert_equal [ photo ], update.attachments.blobs
    assert_not Issues::Draft.exists?(draft.id)
    assert draft.author.issue_subscriptions.exists?(issue: issue)
  end

  test "submit_as_update_of keeps draft photos attached to the update after the draft is destroyed" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    draft.photos.attach(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg", content_type: "image/jpeg")
    draft.save!
    photo = draft.photos.blobs.first

    update = perform_enqueued_jobs do
      draft.submit_as_update_of(issue, text: "Stále tu je", attachments: [ photo.signed_id ])
    end

    assert ActiveStorage::Blob.exists?(photo.id)
    assert_equal [ photo ], update.reload.attachments.blobs
  end

  test "submit_as_update_of lets several drafts update the same issue" do
    issue = issues(:sent_to_responsible)
    photo = ActiveStorage::Blob.create_and_upload!(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg")

    2.times do
      draft = draft_near(issue)
      draft.save!

      assert draft.submit_as_update_of(issue, text: "Stále tu je", attachments: [ photo.signed_id ]).persisted?
    end

    assert_equal 2, Issues::Update.joins(:activity).where(issues_activities: { issue_id: issue.id }).count
  end

  test "submit_as_update_of keeps the draft when the update is invalid" do
    issue = issues(:sent_to_responsible)
    draft = draft_near(issue)
    draft.save!

    update = draft.submit_as_update_of(issue, text: "Bez fotky", attachments: [])

    assert_not update.persisted?
    assert update.errors[:attachments].any?
    assert Issues::Draft.exists?(draft.id)
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

  private

  GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=test-key"

  def draft_with_photo_near(issue, latitude_offset: 0)
    draft = draft_near(issue, latitude_offset: latitude_offset)
    draft.photos.attach(io: file_fixture("graffiti-with-geo.jpg").open, filename: "photo.jpg", content_type: "image/jpeg")
    draft.save!
    draft
  end

  def stub_gemini_duplicates(ids)
    stub_request(:post, GEMINI_URL).to_return(
      headers: { "Content-Type" => "application/json" },
      body: { candidates: [ { content: { parts: [ { text: ids.to_json } ] } } ] }.to_json
    )
  end

  def draft_near(issue, latitude_offset: 0)
    issue.update_columns(latitude: 48.1632, longitude: 17.0494, subcategory_id: issues_subcategories(:one).id)

    Issues::Draft.new(
      author: users(:one),
      latitude: 48.1632 + latitude_offset,
      longitude: 17.0494,
      category: issues_categories(:one),
      subcategory: issues_subcategories(:one),
      checks: []
    )
  end
end
