[
  "Mestská časť",
  "Mesto",
  "Iný subjekt"
].each do |name|
  ResponsibleSubjects::Type.find_or_initialize_by(name: name).tap do |t|
    t.active = true
  end.save!
end

city_district = ResponsibleSubjects::Type.find_by!(name: "Mestská časť")
city = ResponsibleSubjects::Type.find_by!(name: "Mesto")
other = ResponsibleSubjects::Type.find_by!(name: "Iný subjekt")

# Fixed ids: the local Backoffices (config/local_backoffices.yml, started by bin/ops) start with their responsible
# subject's id before bin/activate-seeded-municipalities activates it. Give a new entry the next id.
[
  { id: 1, type: city_district, subject_name: "MÚ Nové Mesto" },
  { id: 2, type: city_district, subject_name: "MÚ Rača" },
  { id: 3, type: city_district, subject_name: "MÚ Vajnory" },
  { id: 4, type: city_district, subject_name: "MÚ Karlova Ves" },
  { id: 5, type: city_district, subject_name: "MÚ Dúbravka" },
  { id: 6, type: city_district, subject_name: "MÚ Lamač" },
  { id: 7, type: city_district, subject_name: "MÚ Devín" },
  { id: 8, type: city_district, subject_name: "MÚ Devínska Nová Ves" },
  { id: 9, type: city_district, subject_name: "MÚ Staré Mesto" },
  { id: 10, type: city_district, subject_name: "MÚ Ružinov" },
  { id: 11, type: city_district, subject_name: "MÚ Vrakuňa" },
  { id: 12, type: city_district, subject_name: "MÚ Podunajské Biskupice" },
  { id: 13, type: city_district, subject_name: "MÚ Záhorská Bystrica" },
  { id: 14, type: city_district, subject_name: "MÚ Petržalka" },
  { id: 15, type: city_district, subject_name: "MÚ Jarovce" },
  { id: 16, type: city_district, subject_name: "MÚ Rusovce" },
  { id: 17, type: city_district, subject_name: "MÚ Čunovo" },

  { id: 18, type: city, subject_name: "Hlavné mesto SR Bratislava" },
  { id: 19, type: city, subject_name: "Banská Bystrica" },
  { id: 20, type: city, subject_name: "Trnava" },
  { id: 21, type: city, subject_name: "Nitra" },
  { id: 22, type: city, subject_name: "Malacky" },
  { id: 23, type: city, subject_name: "Pezinok" },

  { id: 24, type: other, subject_name: "Národná diaľničná spoločnosť" },
  { id: 25, type: other, subject_name: "Mestské lesy v Bratislave" },
  { id: 26, type: other, subject_name: "Dopravný podnik Bratislava, a.s." },
  { id: 27, type: other, subject_name: "Mestská polícia hlavného mesta SR Bratislavy" },
  { id: 28, type: other, subject_name: "Iný subjekt" },
  { id: 29, type: other, subject_name: "OLO Bratislava" }
].each do |data|
  bratislava = Municipality.find_by(name: "Bratislava")
  municipality, municipality_district = case data[:type]
  when city_district
    [ bratislava, bratislava&.municipality_districts&.find_by(name: data[:subject_name].delete_prefix("MÚ ")) ]
  when city
    [ Municipality.find_by(name: data[:subject_name].delete_prefix("Hlavné mesto SR ")), nil ]
  else
    [ data[:subject_name].include?("Bratislav") ? bratislava : nil, nil ]
  end

  ResponsibleSubject.find_or_initialize_by(subject_name: data[:subject_name]).tap do |rs|
    rs.id ||= data[:id]
    rs.responsible_subjects_type = data[:type]
    rs.name = data[:subject_name]
    rs.municipality = municipality
    rs.municipality_district = municipality_district
    rs.email = "#{data[:subject_name].parameterize}@not-existing-domain.com"
    # the responsible subject of an inactive municipality waits for responsible_subjects:activate_basic,
    # which activates it as BASIC
    waiting_for_activation = municipality.present? && !municipality.active?
    rs.active = !waiting_for_activation
    # BASIC, only responsible_subjects:activate_pro or upgrade_to_pro make one PRO, together with its Backoffice
    rs.pro = false
  end.save!
end
# responsible subjects created later (e.g. by activate_basic) get ids after the seeded ones
ActiveRecord::Base.connection.reset_pk_sequence!("responsible_subjects")
