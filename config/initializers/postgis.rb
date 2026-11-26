ActiveRecord::SchemaDumper.ignore_tables = [ "spatial_ref_sys" ]

# The plain postgresql adapter doesn't know the PostGIS geometry type and warns
# "unknown OID ... failed to recognize type of 'boundary'" whenever it loads the columns
# of municipality_boundaries. We only work with geometries in SQL, so map them to a string type.
ActiveSupport.on_load(:active_record_postgresqladapter) do
  singleton_class.prepend(Module.new do
    def initialize_type_map(m)
      super
      m.register_type "geometry", ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:geometry)
    end
  end)
end
