// Sample data shaped like ProfilesHelper#preferred_places_options.
// Pre-selected items reproduce the "a ďalšie" problem.
const raw = [
  ["Banská Bystrica", []],
  ["Bardejov", []],
  ["Bratislava", ["Čunovo", "Devín", "Devínska Nová Ves", "Dúbravka", "Jarovce", "Karlova Ves", "Lamač", "Nové Mesto", "Petržalka", "Podunajské Biskupice", "Rača", "Rusovce", "Ružinov", "Staré Mesto", "Vajnory", "Vrakuňa", "Záhorská Bystrica"]],
  ["Humenné", []],
  ["Komárno", []],
  ["Košice", ["Barca", "Dargovských hrdinov", "Džungľa", "Juh", "Kavečany", "Lorinčík", "Luník IX", "Myslava", "Nad jazerom", "Pereš", "Poľov", "Sever", "Staré Mesto", "Šaca", "Šebastovce", "Ťahanovce", "Vyšné Opátske", "Západ"]],
  ["Levice", []],
  ["Malacky", []],
  ["Martin", []],
  ["Michalovce", []],
  ["Nitra", []],
  ["Pezinok", []],
  ["Piešťany", []],
  ["Poprad", []],
  ["Prešov", []],
  ["Senec", []],
  ["Spišská Nová Ves", []],
  ["Trenčín", []],
  ["Trnava", []],
  ["Zvolen", []],
  ["Žilina", []],
]

const selected = new Set([
  "Bratislava - Petržalka",
  "Bratislava - Ružinov",
  "Bratislava - Staré Mesto",
  "Košice",
  "Pezinok",
  "Senec",
])

let municipalityId = 1
let districtId = 100

export const municipalities = raw.map(([name, districts]) => ({
  id: municipalityId++,
  label: name,
  full_label: name,
  selected: selected.has(name),
  is_district: false,
  districts: districts.map(d => ({
    id: districtId++,
    label: d,
    full_label: `${name} - ${d}`,
    selected: selected.has(`${name} - ${d}`),
    is_district: true,
  })),
}))
