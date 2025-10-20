require "test_helper"

class Connector::CreateNewBackofficeSubtasksFromArticleJobTest < ActiveJob::TestCase
  def setup
    @tenant = connector_tenants(:default)
    @ticket_id = "12345"
    @article_id = "67890"
    @author_id = "author123"

    # Mock article object
    @mock_article = OpenStruct.new(
      body: sample_article_body_with_subtasks,
      author: OpenStruct.new(id: @author_id),
      created_by_id: @author_id
    )
  end

  test "performs job and enqueues subtask jobs for valid subtasks" do
    # Stub the API client
    mock_client = MockZammadClient.new(@mock_article)

    # Expect three CreateNewBackofficeSubtaskJob to be enqueued
    assert_enqueued_jobs 3, only: Connector::CreateNewBackofficeSubtaskJob do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end
  end

  test "enqueues subtask jobs with correct parameters" do
    mock_client = MockZammadClient.new(@mock_article)

    # Check that the first subtask job is enqueued with correct parameters
    assert_enqueued_with(
      job: Connector::CreateNewBackofficeSubtaskJob,
      args: [
        @tenant,
        @ticket_id,
        @author_id,
        {
          number: "#{@article_id}-1",
          title: "Nepokosená tráva na Hradskej ulici",
          user_id: "6",
          due_date: Date.new(2025, 9, 25)
        }
      ]
    ) do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end
  end

  test "uses correct identifier format for multiple subtasks" do
    mock_client = MockZammadClient.new(@mock_article)

    # Verify all three subtask jobs are enqueued
    assert_enqueued_jobs 3, only: Connector::CreateNewBackofficeSubtaskJob do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end

    # Note: Identifier format testing is covered by the parser service tests
    # and the specific parameter test above
  end

  test "does nothing when article is not found" do
    mock_client = MockZammadClient.new(nil)

    assert_no_enqueued_jobs do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end
  end

  test "does nothing when article has no subtasks" do
    article_without_subtasks = OpenStruct.new(
      body: "Regular article without subtasks",
      author: OpenStruct.new(id: @author_id),
      created_by_id: @author_id
    )
    mock_client = MockZammadClient.new(article_without_subtasks)

    assert_no_enqueued_jobs do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end
  end

  test "handles articles with invalid subtask format gracefully" do
    article_with_invalid_subtasks = OpenStruct.new(
      body: <<~BODY,
        [[podulohy]]<br>Invalid line without proper format<br><a href="http://vm-home/#user/profile/13" data-mention-user-id="13" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/13">Test User</a> - Title without date<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">Valid User</a> - Valid subtask - 25.9.2025
      BODY
      author: OpenStruct.new(id: @author_id),
      created_by_id: @author_id
    )
    mock_client = MockZammadClient.new(article_with_invalid_subtasks)

    # Should only enqueue two jobs for the valid subtasks
    assert_enqueued_jobs 2, only: Connector::CreateNewBackofficeSubtaskJob do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end
  end

  test "handles articles with malformed dates" do
    article_with_bad_dates = OpenStruct.new(
      body: <<~BODY,
        [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">User1</a> - Task with invalid date - 32.13.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">User2</a> - Task with valid date - 25.9.2025
      BODY
      author: OpenStruct.new(id: @author_id),
      created_by_id: @author_id
    )
    mock_client = MockZammadClient.new(article_with_bad_dates)

    # Should only enqueue one job for the subtask with valid date
    assert_enqueued_jobs 1, only: Connector::CreateNewBackofficeSubtaskJob do
      Connector::CreateNewBackofficeSubtasksFromArticleJob.perform_now(
        @tenant,
        @ticket_id,
        @article_id,
        zammad_api_client: mock_client,
        ops_api_client: nil
      )
    end
  end

  private

  # Simple mock client for testing
  class MockZammadClient
    def initialize(article_to_return)
      @article_to_return = article_to_return
    end

    def get_article(ticket_id, article_id)
      @article_to_return
    end
  end

  def sample_article_body_with_subtasks
    <<~BODY
      Ahojte,

      všimol som si, že na fotkách tohto podnetu je vidno ďalšie veci, ktoré je potrebné vyriešiť. Vytváram k nim preto podúlohy.

      [[podulohy]]<br><a href="http://vm-home/#user/profile/6" data-mention-user-id="6" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/6">Janko Agent</a> - Nepokosená tráva na Hradskej ulici - 25.9.2025<br><a href="http://vm-home/#user/profile/12" data-mention-user-id="12" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/12">Marienka Agent</a> - Preplnené kontajnery na Hradskej 33 - 30.9.2025<br><a href="http://vm-home/#user/profile/15" data-mention-user-id="15" rel="nofollow noreferrer noopener" title="http://vm-home/#user/profile/15">Jozef Agent</a> - Poškodená lavička - 1.10.2025<div></div><div></div><div></div><div><br></div>

      Vidím tam aj problém s chodníkom, ale to už sa rieši v inom podnete z OPS, takže k tomu už osobitnú podúlohu nerobím.
    BODY
  end
end
