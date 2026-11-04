require "application_system_test_case"

class Issues::ResponsibleSubjectHistoryTest < ApplicationSystemTestCase
  test "timeline labels a missing responsible subject the same way on both sides of a change" do
    issue = issues(:two)
    subject = responsible_subjects(:one)
    issue.update!(responsible_subject: nil)

    issue.update!(responsible_subject: subject)
    issue.update!(responsible_subject: nil)
    issue.update!(responsible_subject: subject)

    visit issue_path(issue)

    assert_selector ".state-change-message", text: "Zmena zodpovedného subjektu", count: 3
    assert_selector ".state-change-message .state-badge", text: "neznámy", count: 3
    assert_selector ".state-change-message .state-badge", text: subject.subject_name, count: 3
    assert_no_text "žiadny"
  end

  test "sidebar shows an issue without a responsible subject as unknown" do
    issue = issues(:two)
    issue.update!(responsible_subject: nil)

    visit issue_path(issue)

    assert_selector ".information-wrapper", text: "Zodpovedný:\nneznámy"
    assert_no_text "Nikto"
  end
end
