require "test_helper"
class EmailParserTest < ActiveSupport::TestCase
  test "remove quoted content" do
    html = <<-HTML
      <div>
        <blockquote>Quoted content</blockquote>
        <p>Actual message</p>
      </div>
    HTML

    result = EmailParser.parse_text(html)
    assert_equal("Actual message", result)
  end

  test "remove gmail quote" do
    html = <<-HTML
      <div>
        <blockquote class="gmail_quote">Gmail quoted content</blockquote>
        <p>Actual message</p>
      </div>
    HTML

    result = EmailParser.parse_text(html)
    assert_equal("Actual message", result)
  end
  test "remove divRplyFwdMsg content" do
    html = <<-HTML
      <div>
        <div id="divRplyFwdMsg">DivRplyFwdMsg content</div>
        <p>Actual message</p>
      </div>
    HTML

    result = EmailParser.parse_text(html)
    assert_equal("Actual message", result)
  end

  test "responsible_subject_emails" do
    html = File.read("test/fixtures/files/responsible_subject_emails/backoffice_comment.html")
    result = EmailParser.parse_text(html)
    expected = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus sit amet accumsan quam, nec elementum nisl. In
hac habitasse platea dictumst. Suspendisse congue velit quis magna laoreet, sed finibus quam scelerisque. Sed
bibendum maximus ante vitae varius. Quisque a enim quis risus mattis gravida ut auctor erat. Integer id
fringilla sapien. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec
vel sem vitae ante luctus aliquam. Quisque massa lacus, dignissim sit amet dui nec, viverra cursus libero.
Aliquam id scelerisque ipsum, non consequat massa. Phasellus tincidunt, felis a accumsan convallis, purus est
vulputate sapien, sed molestie enim tellus sagittis enim. Duis sapien ligula, congue vel libero eget, consequat
rhoncus nulla. Morbi euismod leo diam, non aliquam nulla dapibus nec. Curabitur varius efficitur turpis. Sed
laoreet eros sed ante blandit, mattis volutpat urna accumsan. Ut pellentesque tortor non pharetra tempor.

            S pozdravom,
            Meno"
    assert_equal(expected, result)
  end

  test "responsible_subject_email from outlook handlova" do
    html = File.read("test/fixtures/files/responsible_subject_emails/backoffice_outlook_handlova.html")
    result = EmailParser.parse_text(html)
    expected = "Dobrý deň,\n\nkosenie sa uskutočňuje v dvoch fázach. Najprv zamestnanci spoločnosti HATER-HANDLOVÁ pokosia väčšie plochy, kde sa využívajú aj mechanizmy a následne miesta dokončia manuálne aktivační pracovníci, ktorí sa postarajú o ťažšie prístupné miesta ako aj odvoz pohrabanej trávy.\n\nĎakujeme za trpezlivosť.\nMeno\nreferentka oddelenia marketingu a komunikácie\n0912345678\n046/1234567\nexample@example\nwww.handlova.sk\n\nMestský úrad Handlová\nNám. baníkov 7\n972 51 Handlová"
    assert_equal(expected, result)
  end

  test "email from Lucenec" do
    html = File.read("test/fixtures/files/responsible_subject_emails/lucenec.html")
    result = EmailParser.parse_text(html)
    expected = File.read("test/fixtures/files/responsible_subject_emails/lucenec_expected.txt").strip
    assert_equal(expected, result)
  end

  test "email from Lucenec 2" do
    html = File.read("test/fixtures/files/responsible_subject_emails/lucenec2.html")
    result = EmailParser.parse_text(html)
    expected = File.read("test/fixtures/files/responsible_subject_emails/lucenec2_expected.txt").strip
    assert_equal(expected, result)
  end

  test "email from Ivanka pri Dunaji" do
    html = File.read("test/fixtures/files/responsible_subject_emails/ivanka.html")
    result = EmailParser.parse_text(html)
    expected = File.read("test/fixtures/files/responsible_subject_emails/ivanka_expected.txt").strip
    assert_equal(expected, result)
  end

  test "email from Puchov" do
    html = File.read("test/fixtures/files/responsible_subject_emails/puchov.html")
    result = EmailParser.parse_text(html)
    expected = File.read("test/fixtures/files/responsible_subject_emails/puchov_expected.txt").strip
    assert_equal(expected, result)
  end
end
