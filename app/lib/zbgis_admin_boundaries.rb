require "sqlite3"
require "zip"

# Reads official Slovak administrative boundaries from the GKÚ ZBGIS dataset
# instead of querying the public Overpass API (which frequently fails with 502).
#
# Source: https://opendata.skgeodesy.sk/static/ZBGIS/usj/ah_gpkg_0_sjtsk03.zip
# Layer `obec_0` holds all 2927 municipalities, including the city parts of
# Bratislava ("Bratislava-Staré Mesto", ...) and Košice ("Košice-Sever", ...),
# which we use as district boundaries. Geometries are stored in S-JTSK03
# (EPSG:8353) and reprojected to WGS84 (EPSG:4326) in PostGIS on import.
module ZbgisAdminBoundaries
  URL = "https://opendata.skgeodesy.sk/static/ZBGIS/usj/ah_gpkg_0_sjtsk03.zip"
  GPKG_NAME = "USJ_hranice_0.gpkg"
  SRID = 8353 # S-JTSK03 / Krovak East-North

  # Whole-city municipalities whose parts are separate rows in obec_0.
  CITY_PART_PREFIXES = {
    "Bratislava" => "Bratislava-",
    "Košice" => "Košice-"
  }.freeze

  Municipality = Data.define(:code, :name, :wkb_hex)

  class << self
    def zip_path
      if ENV["ZBGIS_ZIP_PATH"].present?
        Pathname.new(ENV["ZBGIS_ZIP_PATH"])
      else
        Rails.root.join("tmp/zbgis_ah.zip")
      end
    end

    # Downloads the ZBGIS archive unless a usable copy is cached locally.
    # Set ZBGIS_REFRESH=1 to force re-download, ZBGIS_ZIP_PATH to use own file.
    def ensure_downloaded
      return zip_path if zip_path.exist? && zip_path.size.positive? && ENV["ZBGIS_REFRESH"] != "1"

      puts "Downloading ZBGIS administrative boundaries (#{URL})..."
      zip_path.dirname.mkpath
      URI.parse(URL).open("User-Agent" => "www.odkazprestarostu.sk") do |remote|
        File.binwrite(zip_path, remote.read)
      end
      zip_path
    end

    # Yields every row of the `obec_0` layer as a Municipality.
    def each_municipality
      return enum_for(:each_municipality) unless block_given?

      ensure_downloaded
      with_gpkg do |db|
        db.execute("SELECT IDN4, NM4, SHAPE FROM obec_0") do |row|
          code, name, shape = row["IDN4"], row["NM4"], row["SHAPE"]
          next if shape.nil?

          yield Municipality.new(code: code, name: name, wkb_hex: decode_wkb_hex(shape))
        end
      end
    end

    # Returns the whole-city name when the row is a Bratislava/Košice city part, else nil.
    def city_for_part(name)
      CITY_PART_PREFIXES.each do |city, prefix|
        return city if name.start_with?(prefix)
      end
      nil
    end

    # Strips the "Bratislava-"/"Košice-" prefix to get the district name.
    def district_name(name)
      CITY_PART_PREFIXES.each_value do |prefix|
        return name.delete_prefix(prefix) if name.start_with?(prefix)
      end
      name
    end

    # Makes sure PostGIS knows SRID 8353, using the definition bundled in the GPKG.
    def ensure_srid!
      return if ActiveRecord::Base.connection.select_value(
        ActiveRecord::Base.sanitize_sql([ "SELECT COUNT(*) FROM spatial_ref_sys WHERE srid = ?", SRID ])
      ).positive?

      definition = with_gpkg do |db|
        db.get_first_value("SELECT definition FROM gpkg_spatial_ref_sys WHERE srs_id = ?", SRID)
      end
      raise "SRID #{SRID} missing in both PostGIS and the ZBGIS file" if definition.blank?

      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql([
          "INSERT INTO spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) VALUES (?, 'EPSG', ?, ?, '')",
          SRID, SRID, definition
        ])
      )
    end

    # Decodes a GeoPackageBinary blob into a lowercase hex-encoded WKB string.
    def decode_wkb_hex(blob)
      blob = blob.to_s.b
      raise "Not a GeoPackage geometry" unless blob.byteslice(0, 2) == "GP"

      flags = blob.getbyte(3)
      raise "Empty GeoPackage geometry" if (flags & 0x10) != 0
      raise "Extended GeoPackage header not supported" if (flags & 0x20) != 0

      envelope_sizes = [ 0, 32, 48, 48, 64 ]
      offset = 8 + envelope_sizes.fetch((flags >> 1) & 0x7)

      blob.byteslice(offset..).unpack1("H*")
    end

    private

    def with_gpkg
      gpkg_path = extract_gpkg
      db = SQLite3::Database.new(gpkg_path.to_s, readonly: true)
      db.results_as_hash = true
      yield db
    ensure
      db&.close
    end

    def extract_gpkg
      dest = zip_path.dirname.join(GPKG_NAME)
      return dest if dest.exist? && dest.size.positive? && ENV["ZBGIS_REFRESH"] != "1"

      Zip::File.open(zip_path) do |zip|
        entry = zip.find_entry(GPKG_NAME) or raise "Missing #{GPKG_NAME} in #{zip_path}"
        entry.extract(dest) { true }
      end
      dest
    end
  end
end
