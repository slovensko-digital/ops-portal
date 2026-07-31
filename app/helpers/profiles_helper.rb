module ProfilesHelper
  def preferred_places_options(user, municipalities)
    municipalities.map do |m|
      {
        value: "municipality_#{m.id}",
        label: m.name,
        selected: user.preferred_places.include?("municipality_#{m.id}"),
        is_district: false,
        districts: m.active_districts.map do |md|
          {
            value: "district_#{md.id}",
            label: "#{m.name} - #{md.name}",
            selected: user.preferred_places.include?("district_#{md.id}"),
            is_district: true
          }
        end
      }
    end
  end
end
