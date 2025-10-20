require "test_helper"

class Connector::SubtaskParserTest < ActiveSupport::TestCase
  def setup
    @sample_article_body = <<~BODY
      Ahojte,

      všimol som si, že na fotkách tohto podnetu je vidno ďalšie veci, ktoré je potrebné vyriešiť. Vytváram k nim preto podúlohy.

      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Nepokosená tráva na Hradskej ulici - 25.9.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Preplnené kontajnery na Hradskej 33 - 30.9.2025<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">Jozef Agent</a> - Poškodená lavička - 1.10.2025<div></div><div></div><div></div><div><br></div>

      Vidím tam aj problém s chodníkom, ale to už sa rieši v inom podnete z OPS, takže k tomu už osobitnú podúlohu nerobím.
    BODY
  end

  test "parses valid subtasks correctly" do
    subtasks = Connector::SubtaskParser.parse_subtasks(@sample_article_body)

    assert_equal 3, subtasks.length

    # First subtask
    assert_equal "6", subtasks[0].user_id
    assert_equal "Nepokosená tráva na Hradskej ulici", subtasks[0].title
    assert_equal Date.new(2025, 9, 25), subtasks[0].due_date
    assert_includes subtasks[0].line_content, "Janko Agent"

    # Second subtask
    assert_equal "12", subtasks[1].user_id
    assert_equal "Preplnené kontajnery na Hradskej 33", subtasks[1].title
    assert_equal Date.new(2025, 9, 30), subtasks[1].due_date

    # Third subtask
    assert_equal "15", subtasks[2].user_id
    assert_equal "Poškodená lavička", subtasks[2].title
    assert_equal Date.new(2025, 10, 1), subtasks[2].due_date
  end

  test "returns empty array when no subtask tag present" do
    article_body = "Regular article without subtasks"
    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_empty subtasks
  end

  test "returns empty array when subtask tag present but no valid subtask lines" do
    article_body = <<~BODY
      Some text before

      [[podulohy]]<br>Regular text without subtask format<br>Another line
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_empty subtasks
  end

  test "skips invalid subtask lines and parses valid ones" do
    article_body = <<~BODY
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Valid subtask - 25.9.2025<br>Invalid line without proper format<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Another valid one - 30.9.2025<br><a href="http://vm-home/#user/profile/13" data-mention-user-id="13" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/13">Test User</a> - Title without date<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">Jozef Agent</a> - Valid after all - 01.10.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 4, subtasks.length
    assert_equal "6", subtasks[0].user_id
    assert_equal "12", subtasks[1].user_id
    assert_equal "13", subtasks[2].user_id
    assert_equal "15", subtasks[3].user_id
  end

  test "handles malformed dates gracefully" do
    article_body = <<~BODY
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Task with invalid date - 32.13.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Task with valid date - 25.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 1, subtasks.length
    assert_equal "12", subtasks[0].user_id
    assert_equal Date.new(2025, 9, 25), subtasks[0].due_date
  end

  test "handles extra whitespace in subtask lines" do
    article_body = <<~BODY
      [[podulohy]]<br>   <a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a>   -   Task with extra spaces   -   25.9.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a>-No spaces around dashes-30.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 2, subtasks.length
    assert_equal "6", subtasks[0].user_id
    assert_equal "Task with extra spaces", subtasks[0].title
    assert_equal "12", subtasks[1].user_id
    assert_equal "No spaces around dashes", subtasks[1].title
  end

  test "handles usernames with special characters" do
    article_body = <<~BODY
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">User.Name</a> - Task with dot in username - 25.9.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">User_Name</a> - Task with underscore - 26.9.2025<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">User-Name</a> - Task with dash - 27.9.2025<br><a href="http://vm-home/#user/profile/20" data-mention-user-id="20" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/20">User123</a> - Task with numbers - 28.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 4, subtasks.length
    assert_equal "6", subtasks[0].user_id
    assert_equal "12", subtasks[1].user_id
    assert_equal "15", subtasks[2].user_id
    assert_equal "20", subtasks[3].user_id
  end

  test "handles titles with special characters and unicode" do
    article_body = <<~BODY
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Úloha s diakritikou áéíóú - 25.9.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Task with (parentheses) and [brackets] - 26.9.2025<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">Jozef Agent</a> - Task with "quotes" and 'apostrophes' - 27.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 3, subtasks.length
    assert_equal "Úloha s diakritikou áéíóú", subtasks[0].title
    assert_equal "Task with (parentheses) and [brackets]", subtasks[1].title
    assert_equal "Task with \"quotes\" and 'apostrophes'", subtasks[2].title
  end

  test "handles different date formats correctly" do
    article_body = <<~BODY
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Single digit day and month - 1.1.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Two digit day and month - 31.12.2025<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">Jozef Agent</a> - Mixed format - 5.12.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 3, subtasks.length
    assert_equal Date.new(2025, 1, 1), subtasks[0].due_date
    assert_equal Date.new(2025, 12, 31), subtasks[1].due_date
    assert_equal Date.new(2025, 12, 5), subtasks[2].due_date
  end

  test "handles multiple subtask tags (uses last one)" do
    article_body = <<~BODY
      First section with subtasks:
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Old Agent</a> - Old subtask - 25.9.2025

      Some text in between

      New section with subtasks:
      [[podulohy]]<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">New Agent 1</a> - New subtask 1 - 26.9.2025<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">New Agent 2</a> - New subtask 2 - 27.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 2, subtasks.length
    assert_equal "12", subtasks[0].user_id
    assert_equal "15", subtasks[1].user_id
  end

  test "has_subtasks? returns true when subtask tag is present" do
    assert Connector::SubtaskParser.has_subtasks?(@sample_article_body)
  end

  test "has_subtasks? returns false when no subtask tag present" do
    assert_not Connector::SubtaskParser.has_subtasks?("Regular article without subtasks")
  end

  test "handles empty article body" do
    assert_empty Connector::SubtaskParser.parse_subtasks("")
    assert_not Connector::SubtaskParser.has_subtasks?("")
  end

  test "handles nil article body gracefully" do
    assert_empty Connector::SubtaskParser.parse_subtasks(nil)
    assert_not Connector::SubtaskParser.has_subtasks?(nil)
  end

  test "ignores lines that don't contain user mentions" do
    article_body = <<~BODY
      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Valid subtask - 25.9.2025<br>Regular line without mention - Should be ignored - 26.9.2025<br>Another regular line - Should be ignored - 27.9.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Another valid subtask - 28.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 2, subtasks.length
    assert_equal "6", subtasks[0].user_id
    assert_equal "12", subtasks[1].user_id
  end

  test "preserves original line content in SubtaskData" do
    article_body = <<~BODY
      [[podulohy]]<br>   <a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a>   -   Task with extra spaces   -   25.9.2025
    BODY

    subtasks = Connector::SubtaskParser.parse_subtasks(article_body)

    assert_equal 1, subtasks.length
    assert_includes subtasks[0].line_content, "Janko Agent"
    assert_includes subtasks[0].line_content, "Task with extra spaces"
  end
end
