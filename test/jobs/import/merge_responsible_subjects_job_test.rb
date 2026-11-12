require "test_helper"

class Import::MergeResponsibleSubjectsJobTest < ActiveJob::TestCase
  test "moves portal users of merged responsible subjects to the main one" do
    main = responsible_subjects(:pro)
    merged = responsible_subjects(:two)
    user = users(:responsible_subject)
    user.update!(responsible_subject: merged)

    Import::MergeResponsibleSubjectsJob.perform_now(main_responsible_subject: main, other_responsible_subjects_ids: [ merged.id ])

    assert_equal main, user.reload.responsible_subject
    assert merged.reload.archived?
  end

  test "leaves portal users of other responsible subjects untouched" do
    user = users(:responsible_subject)

    Import::MergeResponsibleSubjectsJob.perform_now(main_responsible_subject: responsible_subjects(:pro), other_responsible_subjects_ids: [ responsible_subjects(:two).id ])

    assert_equal responsible_subjects(:one), user.reload.responsible_subject
  end
end
