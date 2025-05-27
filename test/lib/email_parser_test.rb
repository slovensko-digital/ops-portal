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
end
