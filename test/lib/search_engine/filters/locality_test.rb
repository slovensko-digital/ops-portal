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

  test "a municipality includes all its issues" do
    ids = SearchEngine::Filters::Locality.new([ "Bratislava" ]).apply(Issue.searchable).pluck(:id)

    assert_includes ids, @in_petrzalka.id
    assert_includes ids, @in_ruzinov.id
    assert_includes ids, @without_district.id
  end

  test "districts include only their issues" do
    ids = SearchEngine::Filters::Locality.new([ "Bratislava - Petržalka" ]).apply(Issue.searchable).pluck(:id)

    assert_includes ids, @in_petrzalka.id
    assert_not_includes ids, @in_ruzinov.id
    assert_not_includes ids, @without_district.id
  end

  test "ignores old exclusion values" do
    with_exclusion = SearchEngine::Filters::Locality.new([ "Bratislava", "-Bratislava - Ružinov" ]).apply(Issue.searchable)

    assert_includes with_exclusion.pluck(:id), @in_ruzinov.id
  end

  test "ignores non-string values instead of raising" do
    with_junk = SearchEngine::Filters::Locality.new([ 1, nil, "  ", "Nitra" ]).apply(Issue.searchable)
    clean = SearchEngine::Filters::Locality.new([ "Nitra" ]).apply(Issue.searchable)

    assert_equal clean.pluck(:id).sort, with_junk.pluck(:id).sort
  end
end
