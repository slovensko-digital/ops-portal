require "application_system_test_case"

class Cms::PagesTest < ApplicationSystemTestCase
  setup do
    @category = cms_categories(:aktuality)

    @page_in_root_category = cms_pages(:kontakt)
    @page_in_leaf_category = cms_pages(:holiday_notice)
  end

  test "visiting page the index" do
    visit cms_page_path(@category.slug)
    assert_selector "h1", text: "Aktuality"

    assert_text "New portal"
    assert_text "Holiday Hours Notice"

    refute_text "Not published post"
  end

  test "visiting page detail in root category" do
    visit cms_page_path([ @page_in_root_category.slug ])

    assert_selector "h1", text: "Kontakt"
    assert_text "Ask any question"
  end

  test "visiting page detail in leaf category" do
    visit cms_page_path([ @category.slug, @page_in_leaf_category.slug ])

    assert_selector "h1", text: "Holiday Hours Notice"
    assert_text "upcoming holiday season"
  end

  test "visiting category page detail" do
    visit cms_page_path([ @category.slug, @page_in_leaf_category ])

    assert_selector "h1", text: "Holiday Hours Notice"
    assert_text "upcoming holiday season"
  end
end
