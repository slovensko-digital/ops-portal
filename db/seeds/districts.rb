[
  { id: 1, legacy_id: 1, name: "Banskobystrický kraj" },
  { id: 2, legacy_id: 2, name: "Bratislavský kraj" },
  { id: 3, legacy_id: 3, name: "Košický kraj" },
  { id: 4, legacy_id: 4, name: "Nitriansky kraj" },
  { id: 5, legacy_id: 5, name: "Prešovský kraj" },
  { id: 6, legacy_id: 6, name: "Trenčiansky kraj" },
  { id: 7, legacy_id: 7, name: "Trnavský kraj" },
  { id: 8, legacy_id: 8, name: "Žilinský kraj" }
].each do |data|
  District.find_or_initialize_by(id: data[:id]).update!(legacy_id: data[:legacy_id], name: data[:name])
end

District.connection.reset_pk_sequence!(District.table_name)
