require "application_system_test_case"

class PraisesTest < ApplicationSystemTestCase
  test "sending a praise" do
    login(users(:one).email, "password")

    visit new_praise_path
    assert_selector "h1", text: "Nová pochvala"

    click_button "Odoslať pochvalu"
    assert_text "je povinná položka"

    fill_in "Názov", with: "Upratane"
    fill_in "Text", with: "Som spokojny"
    select "Bratislava", from: "Mesto alebo obec"

    click_button "Odoslať pochvalu"

    assert_text "Pochvala bola odoslaná"
  end

  test "login requirement" do
    visit new_praise_path

    assert_text "a byť prihlásený"
  end
end
