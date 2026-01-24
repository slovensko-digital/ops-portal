module AuthHelper
  def login_as(user)
    login(user.email, "password")
  end

  def login(email, password)
    visit "/login"

    assert_selector "h1", text: "Prihlásenie"

    fill_in "Email", with: email
    fill_in "Heslo", with: password

    click_button "Prihlásiť"

    assert_text "Prihlásenie bolo úspešné"
  end

  def login_via_magic_link(email)
    visit "/login"
    click_on "Prihlásiť sa cez email"

    assert_selector "h1", text: "Prihlásenie bez hesla"

    fill_in "Email", with: email
    click_button "Poslať prihlasovací odkaz"

    assert_text "Email s prihlasovacím odkazom bol odoslaný."

    perform_enqueued_jobs
    email = ActionMailer::Base.deliveries.last
    assert_match(/Prihlásenie do profilu/, email.subject)

    link = email.body.encoded.match(/href="([^"]+)"/)[1]
    link = link.sub(%r{http://example.com}, "")

    visit link

    assert_selector "h1", text: "Dokončiť prihlásenie"
    click_on "Vstúpiť do portálu"

    assert_text "Prihlásenie bolo úspešné"
  end

  def logout
    visit profile_path

    click_button "Odhlásiť sa"

    assert_selector ".flash-message-container", text: "Odhlásenie bolo úspešné"
  end
end
