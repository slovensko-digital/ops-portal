module ProfilesHelper
  def preferred_places(user)
    names = user.preferred_places
    return "&mdash;".html_safe if names.empty?

    names.join(", ")
  end

  def preferred_places_options(user, municipalities)
    user_m_ids = user.municipalities.pluck(:id)
    user_md_ids = user.municipality_districts.pluck(:id)

    municipalities.map do |m|
      {
        id: m.id,
        label: m.name,
        full_label: m.name,
        selected: user_m_ids.include?(m.id),
        is_district: false,
        districts: m.active_districts.map do |md|
          {
            id: md.id,
            label: md.name,
            full_label: "#{m.name} - #{md.name}",
            selected: user_md_ids.include?(md.id),
            is_district: true
          }
        end
      }
    end
  end
end
