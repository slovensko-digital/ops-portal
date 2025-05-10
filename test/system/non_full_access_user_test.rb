require "application_system_test_case"
require "test_helpers/issues/drafts_helper"

class NonFullAccessUserTest < ApplicationSystemTestCase
  setup do
    login_as users(:non_full_access)
  end

  test "unverified user cannot create issue, question or praise" do
    visit root_path
    click_on "Nahlásiť podnet"
    assert_text "overený účet"

    visit root_path
    click_on "Položiť otázku"
    assert_text "overený účet"

    visit root_path
    click_on "Dať pochvalu"
    assert_text "overený účet"
  end

  test "unverified user cannot comment, like or vote on issue but cam subscribe" do
    visit issue_path(issues(:two))
    assert_text "Chcete pridať komentár alebo overiť podnet? Musíme overiť váš účet"

    click_on "Sledovať podnet"
    assert_text "Zrušiť sledovanie"

    find(".share-buttons .button-like").click
    assert_text "overený účet"

    visit issue_path(issues(:two))
    find(".like-dislike-con .button-like").click
    assert_text "overený účet"

    visit issue_path(issues(:two))
    find(".like-dislike-con .button-dislike").click
    assert_text "overený účet"
  end
end
