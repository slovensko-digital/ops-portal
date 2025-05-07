module AuthHelper
  def login(email, password)
    visit "/login"

    assert_selector "h1", text: "Prihlásenie"

    fill_in "Email", with: email
    fill_in "Heslo", with: password

    click_button "Prihlásiť"

    assert_text "Prihlásenie bolo úspešné"
  end

  def logout
    visit "/profile"

    click_button "Odhlásiť sa"

    assert_selector ".flash-message-container", text: "Odhlásenie bolo úspešné"
  end
end
