require "application_system_test_case"

class AnnouncementsTest < ApplicationSystemTestCase
  setup do
    @announcement = announcements(:holiday_notice)
  end

  test "visiting the index" do
    visit announcements_path
    assert_selector "h1", text: "Announcements"

    assert_text "New portal"
    assert_text "Holiday Hours Notice"
  end

  test "visiting detail" do
    visit announcement_path(@announcement)

    assert_selector "h1", text: "Holiday Hours Notice"
    assert_text "upcoming holiday season"
  end

  test "redirects to correct url" do
    visit announcement_path(@announcement.id)

    assert_current_path(/holiday-hours-notice/)

    assert_selector "h1", text: "Holiday Hours Notice"
  end
end
