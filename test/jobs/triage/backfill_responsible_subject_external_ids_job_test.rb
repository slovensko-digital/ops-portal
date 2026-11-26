require "test_helper"

class Triage::BackfillResponsibleSubjectExternalIdsJobTest < ActiveJob::TestCase
  class FakeClient
    attr_reader :created

    def initialize(failing: [])
      @failing = failing
      @created = []
    end

    def create_responsible_subject!(responsible_subject)
      raise "Zammad error" if @failing.include?(responsible_subject)

      @created << responsible_subject
      9000 + @created.size
    end
  end

  test "creates triage users for active responsible subjects without external_id" do
    client = FakeClient.new

    Triage::BackfillResponsibleSubjectExternalIdsJob.new.perform(client: client)

    assert_equal [ responsible_subjects(:one), responsible_subjects(:two) ].sort_by(&:id), client.created.sort_by(&:id)
    assert_match(/\A90\d\d\z/, responsible_subjects(:one).reload.external_id)
    assert_match(/\A90\d\d\z/, responsible_subjects(:two).reload.external_id)
    assert_equal "4242", responsible_subjects(:pro).reload.external_id
    assert_nil responsible_subjects(:archived).reload.external_id
  end

  test "continues with remaining responsible subjects when one fails" do
    client = FakeClient.new(failing: [ responsible_subjects(:one) ])

    Triage::BackfillResponsibleSubjectExternalIdsJob.new.perform(client: client)

    assert_nil responsible_subjects(:one).reload.external_id
    assert_not_nil responsible_subjects(:two).reload.external_id
  end
end
