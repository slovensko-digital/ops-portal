require "test_helper"
require "tmpdir"

class ZbgisAdminBoundariesTest < ActiveSupport::TestCase
  test "decode_wkb_hex strips the GeoPackage header and returns lowercase hex WKB" do
    wkb = square_wkb(0.0, 0.0)
    blob = +"GP".b << [ 0, 0x01 ].pack("CC") << [ ZbgisAdminBoundaries::SRID ].pack("l<") << wkb

    assert_equal wkb.unpack1("H*"), ZbgisAdminBoundaries.decode_wkb_hex(blob)
  end

  test "decode_wkb_hex rejects non-GeoPackage blobs and empty geometries" do
    assert_raises(RuntimeError) { ZbgisAdminBoundaries.decode_wkb_hex("XX".b + "\0" * 10) }

    empty_blob = +"GP".b << [ 0, 0x11 ].pack("CC") << [ ZbgisAdminBoundaries::SRID ].pack("l<")
    assert_raises(RuntimeError) { ZbgisAdminBoundaries.decode_wkb_hex(empty_blob) }
  end

  test "city_for_part detects Bratislava and Košice city parts" do
    assert_equal "Bratislava", ZbgisAdminBoundaries.city_for_part("Bratislava-Ružinov")
    assert_equal "Košice", ZbgisAdminBoundaries.city_for_part("Košice-Sever")
    assert_nil ZbgisAdminBoundaries.city_for_part("Nitra")
  end

  test "district_name strips the city prefix" do
    assert_equal "Ružinov", ZbgisAdminBoundaries.district_name("Bratislava-Ružinov")
    assert_equal "Sever", ZbgisAdminBoundaries.district_name("Košice-Sever")
    assert_equal "Nitra", ZbgisAdminBoundaries.district_name("Nitra")
  end

  test "each_municipality streams rows from the ZBGIS archive" do
    Dir.mktmpdir do |dir|
      with_env("ZBGIS_ZIP_PATH" => build_mini_archive(dir)) do
        rows = ZbgisAdminBoundaries.each_municipality.to_a

        assert_equal [ "Nitra", "Bratislava-Ružinov" ], rows.map(&:name)
        assert_equal [ 500011, 529311 ], rows.map(&:code)
        assert rows.all? { |row| row.wkb_hex.match?(/\A[0-9a-f]+\z/) }
      end
    end
  end

  private

  def with_env(vars)
    old = vars.keys.index_with { |key| ENV[key] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    old.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def build_mini_archive(dir)
    gpkg_path = File.join(dir, ZbgisAdminBoundaries::GPKG_NAME)
    db = SQLite3::Database.new(gpkg_path)
    db.execute("CREATE TABLE obec_0 (OBJECTID INTEGER PRIMARY KEY, IDN4 INTEGER, NM4 TEXT, SHAPE BLOB)")
    db.execute("INSERT INTO obec_0 (IDN4, NM4, SHAPE) VALUES (?, ?, ?)", [ 500011, "Nitra", gp_blob(square_wkb(0.0, 0.0)) ])
    db.execute("INSERT INTO obec_0 (IDN4, NM4, SHAPE) VALUES (?, ?, ?)", [ 529311, "Bratislava-Ružinov", gp_blob(square_wkb(1.0, 1.0)) ])
    db.close

    zip_path = File.join(dir, "ah.zip")
    Zip::File.open(zip_path, create: true) do |zip|
      zip.add(ZbgisAdminBoundaries::GPKG_NAME, gpkg_path)
    end
    zip_path
  end

  def gp_blob(wkb)
    (+"GP".b << [ 0, 0x01 ].pack("CC") << [ ZbgisAdminBoundaries::SRID ].pack("l<") << wkb).b
  end

  def square_wkb(x, y)
    ring = [ x, y, x + 1, y, x + 1, y + 1, x, y + 1, x, y ]
    [ 1 ].pack("C") + [ 3 ].pack("l<") + [ 1 ].pack("l<") + [ 5 ].pack("l<") + ring.pack("E*")
  end
end
