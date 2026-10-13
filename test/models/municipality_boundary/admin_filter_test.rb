require "test_helper"

class MunicipalityBoundary::AdminFilterTest < ActiveSupport::TestCase
  MUNICIPALITIES = %i[bratislava trencin banska_bystrica unmatched_municipality].freeze
  DISTRICTS = %i[stare_mesto ruzinov karlova_ves bratislava_unmatched_district].freeze

  setup do
    municipalities(:trencin).update!(active: false)
  end

  test "keeps all options of a list that is left out and none of an empty one" do
    assert_boundaries MUNICIPALITIES + DISTRICTS
    assert_boundaries [], kinds: []
    assert_boundaries [], matched: []
    assert_boundaries [], kinds: [ "" ]
  end

  test "filters by kind" do
    assert_boundaries MUNICIPALITIES, kinds: [ "municipality" ]
    assert_boundaries DISTRICTS, kinds: [ "district" ]
    assert_boundaries [], kinds: [ "unknown" ]
  end

  test "matches municipality boundaries by municipality and district boundaries by district" do
    assert_boundaries %i[bratislava trencin banska_bystrica stare_mesto ruzinov karlova_ves], matched: [ "matched" ]
    assert_boundaries %i[unmatched_municipality bratislava_unmatched_district], matched: [ "unmatched" ]
  end

  test "filters matched boundaries by the active flag of the municipality, district boundaries by their parent" do
    assert_boundaries %i[bratislava banska_bystrica stare_mesto ruzinov karlova_ves], matched: [ "matched" ], active: [ "true" ]
    assert_boundaries %i[trencin], matched: [ "matched" ], active: [ "false" ]
    assert_boundaries [], matched: [ "matched" ], active: []
  end

  test "keeps unmatched boundaries regardless of the active flag" do
    assert_boundaries %i[trencin unmatched_municipality bratislava_unmatched_district], active: [ "false" ]
    assert_boundaries %i[unmatched_municipality bratislava_unmatched_district], active: []
  end

  test "a selected municipality shows its boundary and all of its districts" do
    assert_boundaries %i[bratislava stare_mesto ruzinov karlova_ves bratislava_unmatched_district],
      municipality_ids: [ municipalities(:bratislava).id ]
  end

  test "a municipality selected with all of its districts, as the tree sends it, keeps its unmatched district boundaries" do
    bratislava = municipalities(:bratislava)

    assert_boundaries %i[bratislava stare_mesto ruzinov karlova_ves bratislava_unmatched_district],
      municipality_ids: [ bratislava.id ], municipality_district_ids: bratislava.municipality_districts.ids
  end

  test "selected districts narrow the district layer and keep their municipality boundary" do
    stare_mesto = municipality_districts(:stare_mesto_ba)

    assert_boundaries %i[bratislava stare_mesto], municipality_district_ids: [ stare_mesto.id ]
    assert_boundaries %i[bratislava trencin stare_mesto],
      municipality_ids: [ municipalities(:trencin).id ], municipality_district_ids: [ stare_mesto.id ]
  end

  test "filters by bbox" do
    assert_boundaries %i[trencin], bbox: "17.9,48.8,18.2,49.0"
  end

  test "ignores a bbox that is not 4 numbers" do
    assert_boundaries MUNICIPALITIES + DISTRICTS, bbox: "17.9,48.8,18.2"
    assert_boundaries MUNICIPALITIES + DISTRICTS, bbox: "17.9,48.8,18.2,49.0,1"
    assert_boundaries MUNICIPALITIES + DISTRICTS, bbox: "17.9,48.8,18.2,north"
  end

  private

  def assert_boundaries(names, **options)
    assert_equal names.map { municipality_boundaries(it).id }.sort, MunicipalityBoundary::AdminFilter.new(**options).boundaries.ids.sort
  end
end
