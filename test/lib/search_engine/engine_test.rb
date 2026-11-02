require "test_helper"

class SearchEngine::EngineTest < ActiveSupport::TestCase
  test "hits are paginated by the page param" do
    engine = SearchEngine.new(filters: [], per_page: 1)

    results = engine.search(Issue.order(:id), { page: "2" })

    assert_equal [ Issue.order(:id).second ], results.hits.to_a
  end

  test "hits span the page range" do
    engine = SearchEngine.new(filters: [], per_page: 1)

    results = engine.search(Issue.order(:id), { page: "1-2" })

    assert_equal Issue.order(:id).limit(2).to_a, results.hits
    assert_equal 2, results.pagination.current_page
    assert_equal 3, results.pagination.next_page
  end
end
