require "test_helper"

class SearchEngine::Filters::LocalityTest < ActiveSupport::TestCase
  setup do
    @bratislava = municipalities(:bratislava)
    @petrzalka = municipality_districts(:"Petržalka")
    @ruzinov = municipality_districts(:"Ružinov")
    visible_state = issues_states(:in_progress)

    @in_petrzalka = issues(:two)
    @in_petrzalka.update_columns(municipality_id: @bratislava.id, municipality_district_id: @petrzalka.id, state_id: visible_state.id)

    @in_ruzinov = issues(:sent_to_responsible)
    @in_ruzinov.update_columns(municipality_id: @bratislava.id, municipality_district_id: @ruzinov.id, state_id: visible_state.id)

    # issues(:praise_published) is in Bratislava and has no district
    @without_district = issues(:praise_published)
  end

  test "exclusion-only list does not filter anything" do
    all = Issue.searchable
    filtered = SearchEngine::Filters::Locality.new([ "-Bratislava - Ružinov" ]).apply(all)

    assert_equal all.count, filtered.count
  end

  test "ignores exclusions whose municipality is not selected" do
    with_orphan = SearchEngine::Filters::Locality.new([ "Nitra", "-Bratislava - Ružinov" ]).apply(Issue.searchable)
    without_orphan = SearchEngine::Filters::Locality.new([ "Nitra" ]).apply(Issue.searchable)

    assert_equal without_orphan.pluck(:id).sort, with_orphan.pluck(:id).sort
  end

  test "ignores non-string values instead of raising" do
    with_junk = SearchEngine::Filters::Locality.new([ 1, nil, "  ", "Nitra" ]).apply(Issue.searchable)
    clean = SearchEngine::Filters::Locality.new([ "Nitra" ]).apply(Issue.searchable)

    assert_equal clean.pluck(:id).sort, with_junk.pluck(:id).sort
  end

  test "excludes selected district but keeps the rest of the municipality including issues without district" do
    ids = SearchEngine::Filters::Locality.new([ "Bratislava", "-Bratislava - Ružinov" ]).apply(Issue.searchable).pluck(:id)

    assert_includes ids, @in_petrzalka.id
    assert_includes ids, @without_district.id
    assert_not_includes ids, @in_ruzinov.id
  end
end
