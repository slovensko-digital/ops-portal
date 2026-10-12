require "test_helper"

class MunicipalityBoundary::AdminFilterTest < ActiveSupport::TestCase
  setup do
    @bratislava = municipalities(:bratislava)
    @bratislava.update!(active: true)
    @trencin = municipalities(:trencin)
    @trencin.update!(active: false)
    @stare_mesto = municipality_districts(:stare_mesto_ba)
    @other_district = MunicipalityDistrict.where(municipality: @bratislava).where.not(id: @stare_mesto.id).first

    @bratislava_boundary = create_municipality_boundary(municipality: @bratislava, center_lat: 48.15, center_lon: 17.1)
    @trencin_boundary = create_municipality_boundary(municipality: @trencin, center_lat: 48.9, center_lon: 18.04)
    @unmatched_municipality = create_municipality_boundary(municipality: nil, center_lat: 48.5, center_lon: 17.5)
    @stare_mesto_boundary = create_municipality_boundary(municipality: @bratislava, district: @stare_mesto, center_lat: 48.15, center_lon: 17.1, size: 0.02)
    @other_district_boundary = create_municipality_boundary(municipality: @bratislava, district: @other_district, center_lat: 48.2, center_lon: 17.2, size: 0.02)
    # district boundaries are imported per municipality, so an unmatched one still has its municipality
    @unmatched_district = create_municipality_boundary(municipality: @bratislava, center_lat: 48.1, center_lon: 17.15, size: 0.02, boundary_kind: "district")
  end

  test "keeps all options of a list that is left out and none of an empty one" do
    assert_ids MunicipalityBoundary.all
    assert_ids [], kinds: []
    assert_ids [], matched: []
    assert_ids [], kinds: [ "" ]
  end

  test "filters by kind" do
    assert_ids [ @bratislava_boundary, @trencin_boundary, @unmatched_municipality ], kinds: [ "municipality" ]
    assert_ids [ @stare_mesto_boundary, @other_district_boundary, @unmatched_district ], kinds: [ "district" ]
    assert_ids [], kinds: [ "unknown" ]
  end

  test "matches municipality boundaries by municipality and district boundaries by district" do
    assert_ids [ @bratislava_boundary, @trencin_boundary, @stare_mesto_boundary, @other_district_boundary ], matched: [ "matched" ]
    assert_ids [ @unmatched_municipality, @unmatched_district ], matched: [ "unmatched" ]
  end

  test "filters matched boundaries by the active flag of the municipality, district boundaries by their parent" do
    assert_ids [ @bratislava_boundary, @stare_mesto_boundary, @other_district_boundary ], matched: [ "matched" ], active: [ "true" ]
    assert_ids [ @trencin_boundary ], matched: [ "matched" ], active: [ "false" ]
    assert_ids [], matched: [ "matched" ], active: []
  end

  test "keeps unmatched boundaries regardless of the active flag" do
    assert_ids [ @trencin_boundary, @unmatched_municipality, @unmatched_district ], active: [ "false" ]
    assert_ids [ @unmatched_municipality, @unmatched_district ], active: []
  end

  test "a selected municipality shows its boundary and all of its districts" do
    assert_ids [ @bratislava_boundary, @stare_mesto_boundary, @other_district_boundary, @unmatched_district ], municipality_ids: [ @bratislava.id ]
  end

  test "selected districts narrow the district layer and keep their municipality boundary" do
    assert_ids [ @bratislava_boundary, @stare_mesto_boundary ], municipality_district_ids: [ @stare_mesto.id ]
    assert_ids [ @bratislava_boundary, @trencin_boundary, @stare_mesto_boundary ],
      municipality_ids: [ @bratislava.id, @trencin.id ], municipality_district_ids: [ @stare_mesto.id ]
  end

  test "filters by bbox" do
    assert_ids [ @trencin_boundary ], bbox: "17.9,48.8,18.2,49.0"
  end

  private

  def assert_ids(expected, **options)
    assert_equal expected.map(&:id).sort, MunicipalityBoundary::AdminFilter.new(**options).boundaries.ids.sort
  end
end
