require "test_helper"

class PageRangeTest < ActiveSupport::TestCase
  test "parse plain page numbers" do
    assert_equal [ 3, 3 ], PageRange.parse("3")
    assert_equal [ 1, 1 ], PageRange.parse(nil)
    assert_equal [ 1, 1 ], PageRange.parse("")
  end

  test "parse page ranges" do
    assert_equal [ 1, 4 ], PageRange.parse("1-4")
    assert_equal [ 2, 5 ], PageRange.parse("2-5")
  end

  test "parse clamps invalid values to the first page" do
    assert_equal [ 1, 1 ], PageRange.parse("blabla")
    assert_equal [ 1, 1 ], PageRange.parse("0")
    assert_equal [ 1, 5 ], PageRange.parse("0-5")
    assert_equal [ 5, 5 ], PageRange.parse("5-2")
    assert_equal [ 1, 1 ], PageRange.parse("2-")
  end

  test "paginate loads the whole range in one query" do
    scope = page_range_scope(12)

    records, pagination = PageRange.paginate(scope, "1-2", 5)

    assert_equal scope.limit(10).to_a, records
    assert_equal 2, pagination.current_page
    assert_equal 3, pagination.next_page
  end

  test "paginate falls back to the first page for an invalid param" do
    scope = page_range_scope(12)

    records, pagination = PageRange.paginate(scope, "nonsense", 5)

    assert_equal scope.limit(5).to_a, records
    assert_equal 1, pagination.current_page
    assert_equal 2, pagination.next_page
  end

  private

  def page_range_scope(count)
    state = Issues::State.find_by(key: "in_progress") || issues_states(:in_progress)

    count.times do |i|
      Issue.create!(
        title: "PageRange test issue #{i}",
        description: "Test description with enough characters to pass validation",
        municipality: Municipality.first,
        state: state,
        category: Issues::Category.first,
        author: users(:one)
      )
    end

    Issue.where("title LIKE 'PageRange test issue %'").order(:id)
  end
end
