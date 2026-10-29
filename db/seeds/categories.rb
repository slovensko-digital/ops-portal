# Categories mirror production, created in the same order so ids (and lookups by name) match

def seed_category(name)
  category = Issues::Category.non_legacy.find_or_initialize_by(name: name)
  category.save!
  yield(category) if block_given?
end

def seed_subcategory(category, name)
  subcategory = Issues::Subcategory.find_or_initialize_by(name: name, category: category)
  subcategory.save!
  yield(subcategory) if block_given?
end

def seed_subtype(subcategory, name)
  Issues::Subtype.find_or_initialize_by(name: name, subcategory: subcategory).save!
end

def seed_legacy(model, attributes, **parent)
  model.find_or_initialize_by(legacy_id: attributes[:legacy_id]).tap do |record|
    record.update!(attributes.except(:subcategories, :subtypes).merge(parent))
  end
end

seed_category("Komunikácie") do |category|
  seed_subcategory(category, "cesta") do |subcategory|
    seed_subtype(subcategory, "výtlk")
    seed_subtype(subcategory, "rozbitá cesta (väčší úsek)")
    seed_subtype(subcategory, "znečistená")
    seed_subtype(subcategory, "neodhrnutá")
    seed_subtype(subcategory, "neposypaná")
    seed_subtype(subcategory, "rozkopaná")
    seed_subtype(subcategory, "poškodená dlažba")
  end
  seed_subcategory(category, "chodník") do |subcategory|
    seed_subtype(subcategory, "výtlk")
    seed_subtype(subcategory, "znečistený")
    seed_subtype(subcategory, "neodhrnutý")
    seed_subtype(subcategory, "neposypaný")
    seed_subtype(subcategory, "rozkopaný")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "poškodená dlažba")
    seed_subtype(subcategory, "bariéra na chodníku")
  end
  seed_subcategory(category, "cyklotrasa") do |subcategory|
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "neoznačená")
    seed_subtype(subcategory, "znečistená")
    seed_subtype(subcategory, "neodhrnutá")
    seed_subtype(subcategory, "neposypaná")
    seed_subtype(subcategory, "výtlk")
  end
  seed_subcategory(category, "schody") do |subcategory|
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "znečistená")
    seed_subtype(subcategory, "neodhrnutá")
    seed_subtype(subcategory, "neposypaná")
    seed_subtype(subcategory, "bariérové")
  end
  seed_subcategory(category, "podjazd/podchod") do |subcategory|
    seed_subtype(subcategory, "potrebná údržba")
  end
  seed_subcategory(category, "most/lávka") do |subcategory|
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "nevhodne umiestnená")
  end
end

seed_category("Mobiliár") do |category|
  seed_subcategory(category, "cyklostojan") do |subcategory|
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "poškodený")
    seed_subtype(subcategory, "zle umiestnený")
  end
  seed_subcategory(category, "fontána") do |subcategory|
    seed_subtype(subcategory, "nefunkčná")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "znečistená")
  end
  seed_subcategory(category, "informačná/smerová tabuľa") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "zle otočená")
    seed_subtype(subcategory, "zle umiestnená")
  end
  seed_subcategory(category, "kôš") do |subcategory|
    seed_subtype(subcategory, "chýbajúce sáčky")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "nevhodne umiestnený")
    seed_subtype(subcategory, "poškodený")
    seed_subtype(subcategory, "preplnený")
  end
  seed_subcategory(category, "kvetináč") do |subcategory|
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "poškodený")
    seed_subtype(subcategory, "posunutý")
    seed_subtype(subcategory, "zanedbaný")
  end
  seed_subcategory(category, "lavička") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "znečistená")
  end
  seed_subcategory(category, "pitná fontána") do |subcategory|
    seed_subtype(subcategory, "nefunkčná")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "znečistená")
  end
  seed_subcategory(category, "rozvodná skriňa") do |subcategory|
    seed_subtype(subcategory, "nebezpečný kábel")
    seed_subtype(subcategory, "poškodená rozvodná skriňa")
  end
  seed_subcategory(category, "socha/pamätník/pietne miesto") do |subcategory|
    seed_subtype(subcategory, "poškodené")
    seed_subtype(subcategory, "znečistené")
  end
  seed_subcategory(category, "verejná toaleta") do |subcategory|
    seed_subtype(subcategory, "nefunkčná")
    seed_subtype(subcategory, "uzavretá")
    seed_subtype(subcategory, "znečistená")
  end
  seed_subcategory(category, "výťah") do |subcategory|
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "poškodený")
    seed_subtype(subcategory, "znečistený")
  end
  seed_subcategory(category, "zábradlie/oplotenie") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "poškodené")
    seed_subtype(subcategory, "zhrdzavené")
  end
end

seed_category("Značenie") do |category|
  seed_subcategory(category, "dopravné zrkadlo") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "poškodené")
    seed_subtype(subcategory, "zle natočené")
  end
  seed_subcategory(category, "priechod pre chodcov") do |subcategory|
    seed_subtype(subcategory, "bariérový")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "zle viditeľný")
  end
  seed_subcategory(category, "protiparkovacia zábrana/stĺpik/biskupský klobúk") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "posunutá")
  end
  seed_subcategory(category, "semafor") do |subcategory|
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "nefunkčný")
    seed_subtype(subcategory, "zle nastavený")
  end
  seed_subcategory(category, "spomaľovač") do |subcategory|
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "poškodený")
  end
  seed_subcategory(category, "vodorovné dopravné značenie") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "neaktuálne")
    seed_subtype(subcategory, "zle viditeľné")
  end
  seed_subcategory(category, "zvislé dopravné značenie") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "neaktuálne")
    seed_subtype(subcategory, "poškodené")
    seed_subtype(subcategory, "vyblednuté")
    seed_subtype(subcategory, "zle otočené")
  end
end

seed_category("Osvetlenie") do |category|
  seed_subcategory(category, "osvetlenie") do |subcategory|
    seed_subtype(subcategory, "nefunknčné")
    seed_subtype(subcategory, "poškodený stĺp")
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "nedostatočné")
    seed_subtype(subcategory, "nevhodné (silné a pod.)")
  end
end

seed_category("Kanalizácia") do |category|
  seed_subcategory(category, "kanalizáčná mriežka") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "upchatá")
  end
  seed_subcategory(category, "kanalizáčná vpusť") do |subcategory|
    seed_subtype(subcategory, "chýbajúci kanalizačný poklop")
    seed_subtype(subcategory, "havária kanalizačného potrubia")
    seed_subtype(subcategory, "poškodený kanalizačný poklop")
    seed_subtype(subcategory, "upchatá")
  end
end

seed_category("Mestská hromadná doprava") do |category|
  seed_subcategory(category, "grafikon / zlé nastavenie cestovného poriadku") do |subcategory|
    seed_subtype(subcategory, "poškodenie vozidla")
  end
  seed_subcategory(category, "MHD zastávka") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "poškodená")
    seed_subtype(subcategory, "znečistená")
  end
  seed_subcategory(category, "služby hromadnej dopravy") do |subcategory|
    seed_subtype(subcategory, "meškanie spojov")
  end
end

seed_category("Ihrisko") do |category|
  seed_subcategory(category, "detské ihrisko") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "poškodené")
    seed_subtype(subcategory, "potrebná údržba")
  end
  seed_subcategory(category, "športové ihrisko") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
    seed_subtype(subcategory, "poškodené")
    seed_subtype(subcategory, "potrebná údržba")
  end
end

seed_category("Verejný poriadok") do |category|
  seed_subcategory(category, "reklama") do |subcategory|
    seed_subtype(subcategory, "nelegálna reklama")
    seed_subtype(subcategory, "nevhodne umiestnená")
    seed_subtype(subcategory, "nebezpečná (na spadnutie a pod)")
  end
  seed_subcategory(category, "neporiadok vo verejnom priestranstve") do |subcategory|
    seed_subtype(subcategory, "neodpratané lístie")
    seed_subtype(subcategory, "neporiadok vo verejnom priestore")
  end
  seed_subcategory(category, "vandalizmus") do |subcategory|
    seed_subtype(subcategory, "rušenie nočného pokoja")
    seed_subtype(subcategory, "pitie alkoholu na verejnom priestore")
  end
  seed_subcategory(category, "iné")
end

seed_category("Dopravné riešenie") do |category|
  seed_subcategory(category, "dopravu spomaľujúce") do |subcategory|
    seed_subtype(subcategory, "návrh na riešenie")
  end
  seed_subcategory(category, "nebezpečné") do |subcategory|
    seed_subtype(subcategory, "návrh na riešenie")
  end
  seed_subcategory(category, "obchádzková trasa") do |subcategory|
    seed_subtype(subcategory, "bariérová")
    seed_subtype(subcategory, "nebezpečná")
    seed_subtype(subcategory, "zle vyznačená")
  end
end

seed_category("Zdieľaná mikromobilita") do |category|
  seed_subcategory(category, "bicykle") do |subcategory|
    seed_subtype(subcategory, "nevhodne umiestnené parkovisko")
    seed_subtype(subcategory, "nevhodne zaparkovaný dopravný prostriedok")
  end
  seed_subcategory(category, "kolobežky") do |subcategory|
    seed_subtype(subcategory, "nevhodne umiestnené parkovisko")
    seed_subtype(subcategory, "nevhodne zaparkovaný dopravný prostriedok")
  end
end

seed_category("Zeleň a znečisťovanie") do |category|
  seed_subcategory(category, "kosenie") do |subcategory|
    seed_subtype(subcategory, "nepravidelne")
  end
  seed_subcategory(category, "strom") do |subcategory|
    seed_subtype(subcategory, "suchý")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "neorezaný")
    seed_subtype(subcategory, "zlomený konár")
    seed_subtype(subcategory, "napadnutý")
    seed_subtype(subcategory, "invazívna rastlina")
    seed_subtype(subcategory, "poškodená podpera")
  end
  seed_subcategory(category, "krík") do |subcategory|
    seed_subtype(subcategory, "suchý")
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "neorezaný")
  end
  seed_subcategory(category, "výsadba") do |subcategory|
    seed_subtype(subcategory, "chýbajúca")
    seed_subtype(subcategory, "neudržiavaná")
  end
  seed_subcategory(category, "ostatná starostlivosť") do |subcategory|
    seed_subtype(subcategory, "iné")
  end
  seed_subcategory(category, "znečisťovanie") do |subcategory|
    seed_subtype(subcategory, "voda, pôda, ovzdušie")
  end
end

seed_category("Stavby") do |category|
  seed_subcategory(category, "budova") do |subcategory|
    seed_subtype(subcategory, "grafiti")
    seed_subtype(subcategory, "nevyužívaná")
    seed_subtype(subcategory, "poškodená")
  end
  seed_subcategory(category, "letná terasa") do |subcategory|
    seed_subtype(subcategory, "preverenie povolenia")
  end
  seed_subcategory(category, "most") do |subcategory|
    seed_subtype(subcategory, "grafiti")
    seed_subtype(subcategory, "poškodený")
  end
  seed_subcategory(category, "stánok") do |subcategory|
    seed_subtype(subcategory, "grafiti")
    seed_subtype(subcategory, "nevyužívaný")
    seed_subtype(subcategory, "poškodený")
  end
end

seed_category("Zvieratá") do |category|
  seed_subcategory(category, "zver v meste") do |subcategory|
    seed_subtype(subcategory, "premnožené hlodavce")
  end
  seed_subcategory(category, "výbehy pre zvieratá") do |subcategory|
    seed_subtype(subcategory, "lesná zver")
    seed_subtype(subcategory, "túlavé mačky/psy")
    seed_subtype(subcategory, "hmyz")
  end
  seed_subcategory(category, "domáce zvieratá") do |subcategory|
    seed_subtype(subcategory, "výbehy pre zvieratá")
    seed_subtype(subcategory, "majitelia - neplnenie povinností")
  end
  seed_subcategory(category, "mŕtvy živočích")
  seed_subcategory(category, "iné")
end

seed_category("Skládky a vraky") do |category|
  seed_subcategory(category, "nelegálne skládky")
  seed_subcategory(category, "vraky motorových vozidiel")
  seed_subcategory(category, "kontajnerové stanovištia") do |subcategory|
    seed_subtype(subcategory, "chýbajúce")
  end
  seed_subcategory(category, "kompostovanie") do |subcategory|
    seed_subtype(subcategory, "chýbajúce komunitné kompostovisko")
    seed_subtype(subcategory, "domácnosti")
  end
end

seed_category("Kontakt so samosprávou") do |category|
  seed_subcategory(category, "mobilná aplikácia mesta") do |subcategory|
    seed_subtype(subcategory, "chýbajúca informácia")
    seed_subtype(subcategory, "neaktuálne informácie")
    seed_subtype(subcategory, "nefunkčná aplikácia")
  end
  seed_subcategory(category, "verejný rozhlas") do |subcategory|
    seed_subtype(subcategory, "chýbajúci")
    seed_subtype(subcategory, "pokazený")
  end
  seed_subcategory(category, "webová stránka mesta") do |subcategory|
    seed_subtype(subcategory, "chýbajúca informácia")
    seed_subtype(subcategory, "neaktuálne informácie")
    seed_subtype(subcategory, "nefunkčná stránka")
  end
end

seed_category("Iné") do |category|
  seed_subcategory(category, "iné")
end

# Legacy categories imported from the old system

[
  { legacy_id: 16, triage_external_id: 1, name: "Cesty a chodníky", name_hu: "Közutak és közterület", alias: "cesty-a-dopravne-znacenie", description: "cesty, cyklotrasy, schody, oplotenie", description_hu: "utak, kerékpárutak, lépcsők, kerítések", weight: 1000, subcategories: [
    { legacy_id: 31, name: "cesta", name_hu: "közút", alias: "neupravene cesty", weight: 1000, subtypes: [
      { legacy_id: 27, name: "výtlk", name_hu: "kátyú", alias: "vytlky-na-ceste", weight: 1000 },
      { legacy_id: 98, name: "rozbitá (väčší úsek)", name_hu: "sérült útburkolat (hosszabb szakaszon)", alias: "rozbitá (väčší úsek)", weight: 900 },
      { legacy_id: 99, name: "znečistená", name_hu: "szennyezett", alias: "znečistená", weight: 500 },
      { legacy_id: 100, name: "neodhrnutá", name_hu: "hóeltakarítás szükséges", alias: "neodhrnutá", weight: 400 },
      { legacy_id: 101, name: "neposypaná", name_hu: "szórás szükséges", alias: "neposypaná ", weight: 300 },
      { legacy_id: 102, name: "rozkopaná", name_hu: "felbontott", alias: "rozkopaná", weight: 200 },
      { legacy_id: 103, name: "poškodená dlažba", name_hu: "sérült útburkolat", alias: "poškodená dlažba", weight: 100 }
    ] },
    { legacy_id: 32, name: "chodník", name_hu: "járda", alias: "neupravene-chodniky", weight: 900, subtypes: [
      { legacy_id: 28, name: "výtlk", name_hu: "kátyú", alias: "vytlky-na-chodniku", weight: 1000 },
      { legacy_id: 234, name: "bariéra na chodníku", name_hu: "akadály a járdán", alias: "bariéra na chodníku", weight: 0 },
      { legacy_id: 107, name: "bariérový", name_hu: "akadály", alias: "bariérový", weight: 0 },
      { legacy_id: 109, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci", weight: 0 },
      { legacy_id: 105, name: "neodhrnutý", name_hu: "hóeltakarítás szükséges", alias: "neodhrnutý", weight: 0 },
      { legacy_id: 106, name: "neposypaný", name_hu: "szórás szükséges", alias: "neposypaný", weight: 0 },
      { legacy_id: 110, name: "poškodená dlažba", name_hu: "sérült utcaburkolat", alias: "poškodená dlažba", weight: 0 },
      { legacy_id: 108, name: "rozkopaný", name_hu: "felbontott", alias: "rozkopaný", weight: 0 },
      { legacy_id: 104, name: "znečistený", name_hu: "szennyezett", alias: "znečistený", weight: 0 }
    ] },
    { legacy_id: 33, name: "cyklotrasa", name_hu: "kerékpárút", alias: "cyklochodníky", weight: 800, subtypes: [
      { legacy_id: 112, name: "chýbajúca", name_hu: "hiányzó", alias: "chýbajúca", weight: 0 },
      { legacy_id: 115, name: "neodhrnutá", name_hu: "hóeltakarítás szükséges", alias: "neodhrnutá", weight: 0 },
      { legacy_id: 113, name: "neoznačená", name_hu: "hiányzó megjelölés", alias: "neoznačená", weight: 0 },
      { legacy_id: 116, name: "neposypaná", name_hu: "szórás szükséges", alias: "neposypaná ", weight: 0 },
      { legacy_id: 111, name: "poškodená", name_hu: "megrongált", alias: "poškodená", weight: 0 },
      { legacy_id: 114, name: "znečistená", name_hu: "szennyezett", alias: "znečistená", weight: 0 }
    ] },
    { legacy_id: 29, name: "schody", name_hu: "lépcsõ", alias: "poskodene-schody", weight: 700, subtypes: [
      { legacy_id: 118, name: "neodhrnuté", name_hu: "hóeltakarítás szükséges", alias: "neodhrnuté", weight: 0 },
      { legacy_id: 119, name: "neposypané", name_hu: "szórás szükséges", alias: "neposypané", weight: 0 },
      { legacy_id: 117, name: "poškodené", name_hu: "megrongált", alias: "poškodené", weight: 0 },
      { legacy_id: 120, name: "znečistené", name_hu: "szennyezett", alias: "znečistené", weight: 0 }
    ] },
    { legacy_id: 95, name: "zábradlie", name_hu: "korlát", alias: "zabradlie", weight: 600, subtypes: [
      { legacy_id: 121, name: "chýbajúce", name_hu: "hiányzó", alias: "chýbajúce ", weight: 0 },
      { legacy_id: 122, name: "poškodené", name_hu: "megrongált", alias: "poškodené", weight: 0 },
      { legacy_id: 123, name: "zhrdzavené", name_hu: "rozsdás", alias: "zhrdzavené", weight: 0 }
    ] },
    { legacy_id: 96, name: "oplotenie", name_hu: "kerítés", alias: "oplotenie", weight: 500, subtypes: [
      { legacy_id: 124, name: "chýbajúce", name_hu: "hiányzó", alias: "chýbajúce ", weight: 0 },
      { legacy_id: 125, name: "poškodené", name_hu: "megrongált", alias: "poškodené", weight: 0 },
      { legacy_id: 126, name: "zhrdzavené", name_hu: "rozsdás", alias: "zhrdzavené", weight: 0 }
    ] },
    { legacy_id: 97, name: "iné", name_hu: "egyéb", alias: "ine", weight: 0 }
  ] },
  { legacy_id: 1, triage_external_id: 2, name: "Zeleň a životné prostredie", name_hu: "Zöldterületek", alias: "priroda-a-zivotne-prostredie", description: "stromy, neporiadok, znečisťovanie", description_hu: "fák, rendetlenség, szennyezés", weight: 900, subcategories: [
    { legacy_id: 127, name: "strom", name_hu: "fa", alias: "strom", weight: 1000, subtypes: [
      { legacy_id: 82, name: "suchý", name_hu: "kiszáradt", alias: "suche-stromy", weight: 1000 },
      { legacy_id: 132, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci", weight: 900 },
      { legacy_id: 133, name: "neorezaný", name_hu: "metszést igényel", alias: "neorezaný", weight: 800 },
      { legacy_id: 134, name: "zlomený konár", name_hu: "törött ág", alias: "zlomený konár ", weight: 700 },
      { legacy_id: 135, name: "napadnutý", name_hu: "fertõzött fa", alias: "napadnutý", weight: 600 },
      { legacy_id: 136, name: "invazívna rastlina", name_hu: "elburjánzott növényzet", alias: "invazívna rastlina", weight: 500 },
      { legacy_id: 223, name: "poškodená podpera", name_hu: "sérült tartó", alias: "poškodená podpera", weight: 0 }
    ] },
    { legacy_id: 128, name: "trávnatá plocha", name_hu: "füves terület", alias: "trávnatá plocha ", weight: 900, subtypes: [
      { legacy_id: 137, name: "vyschnutá", name_hu: "kiszáradt", alias: "vyschnutá", weight: 900 },
      { legacy_id: 138, name: "vyjazdené koľaje", name_hu: "kitaposott nyomvonalak", alias: "vyjazdené koľaje", weight: 800 },
      { legacy_id: 83, name: "nepokosená", name_hu: "kaszálást igényel", alias: "nepokosene-travnate-plochy", weight: 100 }
    ] },
    { legacy_id: 129, name: "krík", name_hu: "bokor", alias: "krík", weight: 800, subtypes: [
      { legacy_id: 139, name: "suchý", name_hu: "száraz", alias: "suchý ", weight: 1000 },
      { legacy_id: 140, name: "neostrihaný", name_hu: "metszést igényel", alias: "neostrihaný ", weight: 900 },
      { legacy_id: 141, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci", weight: 800 }
    ] },
    { legacy_id: 130, name: "zviera", name_hu: "állat", alias: "zviera", weight: 700, subtypes: [
      { legacy_id: 90, name: "uhynuté", name_hu: "elpusztult", alias: "uhynute-zvierata", weight: 1000 },
      { legacy_id: 89, name: "túlavé", name_hu: "kóbor", alias: "túlavé", weight: 900 },
      { legacy_id: 222, name: "deratizácia", name_hu: "rágcsáló", alias: "deratizácia", weight: 0 }
    ] },
    { legacy_id: 36, name: "neporiadok a odpadky", name_hu: "rendetlenség és szemét", alias: "znecistovanie-pri-stavbe", weight: 600, subtypes: [
      { legacy_id: 87, name: "čierne skládky", name_hu: "fekete szemétlerakat", alias: "cierne-skladky", weight: 0 },
      { legacy_id: 85, name: "neodpratané lístie", name_hu: "eltakarításra váró falevelek", alias: "neodpratane-listie", weight: 0 },
      { legacy_id: 88, name: "neporiadok vo verejnom priestranstve", name_hu: "rendetlenség a közterületen", alias: "neporiadok-vo-verejnom-priestran", weight: 0 }
    ] },
    { legacy_id: 131, name: "znečisťovanie", name_hu: "szennyezés", alias: "znečisťovanie", weight: 500, subtypes: [
      { legacy_id: 86, name: "ovzdušia", name_hu: "légszennyezés", alias: "ovzdušia ", weight: 0 },
      { legacy_id: 143, name: "pôdy", name_hu: "talajszennyezés", alias: "pôdy", weight: 0 },
      { legacy_id: 142, name: "vody", name_hu: "vízszennyezés", alias: "vody", weight: 0 }
    ] },
    { legacy_id: 91, name: "iné", name_hu: "egyéb", alias: "ine", weight: 400 }
  ] },
  { legacy_id: 25, triage_external_id: 3, name: "Dopravné značenie", name_hu: "Közúti jelzések", alias: "dopravne-znacenie", description: "značky, semafory, stĺpiky", description_hu: "jelzőtáblák, közlekedési lámpák, pollerek", weight: 800, subcategories: [
    { legacy_id: 144, name: "zvislá značka", name_hu: "közúti jelzõtábla", alias: "vertikálna značka", weight: 1000, subtypes: [
      { legacy_id: 47, name: "chýbajúca", name_hu: "hiányzó", alias: "chýbajúca", weight: 0 },
      { legacy_id: 46, name: "neaktuálna", name_hu: "nem aktuális", alias: "neaktuálna ", weight: 0 },
      { legacy_id: 45, name: "poškodená", name_hu: "megrongált", alias: "poškodená", weight: 0 },
      { legacy_id: 145, name: "vyblednutá", name_hu: "kifehéredett", alias: "vyblednutá ", weight: 0 },
      { legacy_id: 233, name: "zle otočená", name_hu: "rossz fordulás", alias: "zle otočená", weight: 0 }
    ] },
    { legacy_id: 42, name: "semafor", name_hu: "közlekedési lámpa", alias: "semafor", weight: 900, subtypes: [
      { legacy_id: 148, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci ", weight: 0 },
      { legacy_id: 146, name: "nefunkčný", name_hu: "nem mûködõ", alias: "nefunkčný", weight: 0 },
      { legacy_id: 147, name: "zle nastavený", name_hu: "rosszul beállított", alias: "zle nastavený", weight: 0 }
    ] },
    { legacy_id: 43, name: "dopravné zrkadlo", name_hu: "közlekedési tükör", alias: "dopravné zrkadlo", weight: 800, subtypes: [
      { legacy_id: 149, name: "chýbajúce", name_hu: "hiányzó", alias: "chýbajúce ", weight: 0 },
      { legacy_id: 151, name: "poškodené", name_hu: "megrongált", alias: "poškodené", weight: 0 },
      { legacy_id: 150, name: "zle natočené", name_hu: "rossz szög", alias: "zle natočené", weight: 0 }
    ] },
    { legacy_id: 212, name: "stĺpik", name_hu: "poller (oszlop)", alias: "stlpik", weight: 700, subtypes: [
      { legacy_id: 213, name: "chýbajúci", name_hu: "hiányzó", alias: "chybajuci", weight: 1000 },
      { legacy_id: 214, name: "poškodený", name_hu: "megrongált", alias: "poskodeny", weight: 900 },
      { legacy_id: 215, name: "nadbytočný", name_hu: "felesleges", alias: "nadbytocny", weight: 800 }
    ] },
    { legacy_id: 155, name: "spomaľovač", name_hu: "fekvõrendõr", alias: "spomaľovač", weight: 600, subtypes: [
      { legacy_id: 156, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci ", weight: 0 },
      { legacy_id: 157, name: "poškodený", name_hu: "megrongált", alias: "poškodený", weight: 0 }
    ] },
    { legacy_id: 158, name: "betónová zábrana (biskupský klobúk)", name_hu: "beton torlasz", alias: "betonova-zabrana", weight: 500, subtypes: [
      { legacy_id: 159, name: "chýbajúca", name_hu: "rosszul látható", alias: "chýbajúca ", weight: 0 },
      { legacy_id: 161, name: "poškodená", name_hu: "megrongált", alias: "poškodená", weight: 0 },
      { legacy_id: 160, name: "posunutá", name_hu: "odébbtolt", alias: "posunutá", weight: 0 }
    ] },
    { legacy_id: 41, name: "priechod pre chodcov", name_hu: "gyalogos-átkelõhely", alias: "priechody-pre-chodcov", weight: 400, subtypes: [
      { legacy_id: 162, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci ", weight: 0 },
      { legacy_id: 163, name: "zle viditeľný", name_hu: "rosszul látható", alias: "zle viditeľný", weight: 0 }
    ] },
    { legacy_id: 48, name: "vodorovná značka", name_hu: "útburkolati jel", alias: "znacky-na-ceste", weight: 300, subtypes: [
      { legacy_id: 164, name: "chýbajúca", name_hu: "hiányzó", alias: "chýbajúca", weight: 0 },
      { legacy_id: 165, name: "neaktuálna", name_hu: "nem aktuális", alias: "neaktuálna ", weight: 0 },
      { legacy_id: 166, name: "zle viditeľná", name_hu: "rosszul látható", alias: "zle viditeľná ", weight: 0 }
    ] },
    { legacy_id: 49, name: "riešenie dopravnej situácie", name_hu: "forgalomrendezés", alias: "zle-nevhodne-dopravne-riesenia", weight: 200, subtypes: [
      { legacy_id: 168, name: "dopravu spomaľujúce", name_hu: "a forgalmat lassító/akadályozó", alias: "dopravu spomaľujúce", weight: 0 },
      { legacy_id: 167, name: "nebezpečné", name_hu: "veszély", alias: "nebezpečné", weight: 0 },
      { legacy_id: 232, name: "nedodržiavanie dopravných predpisov", name_hu: "a közlekedési szabályok be nem tartása", alias: "nedodržiavanie dopravných predpi", weight: 0 }
    ] },
    { legacy_id: 50, name: "iné", name_hu: "egyéb", alias: "ine", weight: 100 }
  ] },
  { legacy_id: 9, triage_external_id: 4, name: "Mestský mobiliár", name_hu: "Közterületek berendezései ", alias: "Mestský mobiliár", description: "koše, ihriská, lavičky, zastávky MHD", description_hu: "szemétkosarak, játszóterek, padok, tömegközlekedési megállók", weight: 700, subcategories: [
    { legacy_id: 169, name: "kôš", name_hu: "szemétkosár", alias: "kôš", weight: 1000, subtypes: [
      { legacy_id: 226, name: "chýbajúce sáčky", name_hu: "hiányzó táskák", alias: "chýbajúce sáčky", weight: 0 },
      { legacy_id: 53, name: "chýbajúci", name_hu: "hiányzó", alias: "chybajuce-kose", weight: 0 },
      { legacy_id: 225, name: "nevhodne umiestnený", name_hu: "helytelenül elhelyezett", alias: "nevhodne umiestnený", weight: 0 },
      { legacy_id: 51, name: "poškodený", name_hu: "megrongált", alias: "poskodene-kose", weight: 0 },
      { legacy_id: 52, name: "preplnený", name_hu: "túltömött", alias: "preplnene-kose", weight: 0 }
    ] },
    { legacy_id: 170, name: "detské ihrisko", name_hu: "játszótér", alias: "detské ihrisko", weight: 900, subtypes: [
      { legacy_id: 171, name: "chýbajúce", name_hu: "hiányzó", alias: "chýbajúce", weight: 0 },
      { legacy_id: 54, name: "poškodené", name_hu: "megrongált", alias: "poskodene-detske-ihriska", weight: 0 },
      { legacy_id: 172, name: "potrebná údržba", name_hu: "karbantartást igényel", alias: "potrebná údržba", weight: 0 }
    ] },
    { legacy_id: 55, name: "lavička", name_hu: "pad", alias: "poskodene-chybajuce-lavicky", weight: 800, subtypes: [
      { legacy_id: 173, name: "chýbajúca", name_hu: "hiányzó", alias: "chýbajúca", weight: 0 },
      { legacy_id: 174, name: "poškodená", name_hu: "megrongált", alias: "poškodená", weight: 0 },
      { legacy_id: 217, name: "znečistená", name_hu: "szennyezett", alias: "znečistená", weight: 0 }
    ] },
    { legacy_id: 56, name: "socha, pamätník", name_hu: "szobor, emlékmû", alias: "zanedbane-pamiatky", weight: 700, subtypes: [
      { legacy_id: 176, name: "poškodená", name_hu: "megrongált", alias: "poškodená", weight: 0 },
      { legacy_id: 175, name: "znečistená", name_hu: "szennyezett", alias: "znečistená", weight: 0 }
    ] },
    { legacy_id: 57, name: "zastávka MHD", name_hu: "tömegközlekedési (autóbusz, trolibusz, villamos) megálló", alias: "zastavky-mhd", weight: 600, subtypes: [
      { legacy_id: 178, name: "chýbajúca", name_hu: "hiányzó", alias: "chýbajúca ", weight: 0 },
      { legacy_id: 177, name: "poškodená", name_hu: "megrongált", alias: "poškodená", weight: 0 },
      { legacy_id: 179, name: "znečistená", name_hu: "szennyezett", alias: "znečistená", weight: 0 }
    ] },
    { legacy_id: 180, name: "cyklostojan", name_hu: "kerékpár tároló", alias: "cyklostojan", weight: 500, subtypes: [
      { legacy_id: 181, name: "chýbajúci", name_hu: "hiányzó", alias: "chýbajúci", weight: 1000 },
      { legacy_id: 182, name: "poškodený", name_hu: "megrongált", alias: "poškodený", weight: 900 },
      { legacy_id: 183, name: "zle umiestnený", name_hu: "rosszul elhelyezett", alias: "zle umiestnený", weight: 800 }
    ] },
    { legacy_id: 218, name: "fontánka", name_hu: "szökőkút", alias: "fontánka", weight: 0, subtypes: [
      { legacy_id: 219, name: "nefunkčná", name_hu: "nem funkcionális", alias: "nefunkčná", weight: 0 },
      { legacy_id: 220, name: "poškodená", name_hu: "sérült", alias: "poškodená", weight: 0 },
      { legacy_id: 221, name: "znečistená", name_hu: "szennyezett", alias: "znečistená", weight: 0 }
    ] },
    { legacy_id: 216, name: "iné", name_hu: "egyéb", alias: "ine", weight: 0 },
    { legacy_id: 227, name: "informačná tabuľa", name_hu: " információs tábla", alias: "informačná tabuľa", weight: 0, subtypes: [
      { legacy_id: 231, name: "chýbajúca", name_hu: "hiányzó", alias: "chýbajúca", weight: 0 },
      { legacy_id: 228, name: "poškodená", name_hu: "sérült", alias: "poškodená", weight: 0 },
      { legacy_id: 229, name: "zle otočená", name_hu: "rossz fordulás", alias: "zle otočená", weight: 0 },
      { legacy_id: 230, name: "zle umiestnená", name_hu: "rosszul van", alias: "zle umiestnená", weight: 0 }
    ] },
    { legacy_id: 235, name: "kvetináč", name_hu: "virágcserép", alias: "kvetinac", weight: 0, subtypes: [
      { legacy_id: 239, name: "chýbajúci", name_hu: "hiányzó", alias: "chybajuc", weight: 0 },
      { legacy_id: 236, name: "poškodený", name_hu: "sérült", alias: "poskodeny", weight: 0 },
      { legacy_id: 237, name: "posunutý", name_hu: "kényszerült", alias: "posunuty", weight: 0 },
      { legacy_id: 238, name: "zanedbaný", name_hu: "elhanyagolt", alias: "zanedbany", weight: 0 }
    ] }
  ] },
  { legacy_id: 184, triage_external_id: 5, name: "Automobily", name_hu: "Gépjármûvek", alias: " Automobily", description: "parkovanie, dlhodobo odstavené vozidlá", description_hu: "parkolás, elhagyott járművek", weight: 600, subcategories: [
    { legacy_id: 4, name: "parkovanie", name_hu: "parkolás", alias: "parkovanie-aut", weight: 1000, subtypes: [
      { legacy_id: 64, name: "chýbajúce miesta", name_hu: "hiányzó parkolóhelyek", alias: "chybajuce-parkovacie-miesta", weight: 0 },
      { legacy_id: 65, name: "nevyznačené miesta", name_hu: "kijelöletlen parkolóhelyek", alias: "nevyznacene-parkovacie-miesta", weight: 0 },
      { legacy_id: 63, name: "problémové", name_hu: "problémás", alias: "problemove-parkovanie", weight: 0 }
    ] },
    { legacy_id: 3, name: "dlhodobo odstavené vozidlá", name_hu: "elhagyott autó", alias: "opustene-nepojazdne-vozidla", weight: 900, subtypes: [
      { legacy_id: 59, name: "vozidlo s EČV, s platnou TK a EK", name_hu: "rendszámtáblával ellátott gépjármû érvényes forgalmi engedéllyel és környezetvédelmi vizsgálattal", alias: "nepojazdne-vozidla-platna-tk-ek", weight: 1000 },
      { legacy_id: 93, name: "vozidlo s EČV, bez platnej TK a EK", name_hu: "rendszámtáblával ellátott gépjármû érvényes forgalmi engedély és környezetvédelmi vizsgálat nélkül", alias: "nepojazdne-vozidla-neplatna-tk", weight: 900 },
      { legacy_id: 60, name: "vozidlo bez EČV, s platnou TK a EK", name_hu: "hiányzó rendszámtábla, érvényes forgalmi engedéllyel és környezetvédelmi vizsgálattal", alias: "opustene-vozidla-bez-ecv-platna-", weight: 800 },
      { legacy_id: 61, name: "vozidlo bez EČV, bez platnej TK a EK", name_hu: "hiányzó rendszámtábla, érvényes forgalmi engedély és környezetvédelmi vizsgálat nélkül", alias: "opustene-vozidla-bez-ecv-neplatn", weight: 700 },
      { legacy_id: 185, name: "nezistené EČV a TK a EK", name_hu: "ismeretlen rendszám, forgalmi engedély és környezetvédelmi vizsgálat", alias: "nezistené EČV a TK a EK  ", weight: 600 },
      { legacy_id: 186, name: "zahraničné vozidlo", name_hu: "külföldi gépjármû", alias: "zahraničné vozidlo", weight: 500 }
    ] },
    { legacy_id: 211, name: "iné", name_hu: "egyéb", alias: "iné", weight: 0 }
  ] },
  { legacy_id: 14, triage_external_id: 6, name: "Verejné služby", name_hu: "Közszolgáltatások", alias: "kanalizacia", description: "osvetlenie, kanalizácia, MHD, web, rozvodné siete", description_hu: "közvilágítás, csatornahálózat, városi tömegközlekedés, honlap, közműhálózat", weight: 500, subcategories: [
    { legacy_id: 187, name: "kanalizácia", name_hu: "csatornahálózat", alias: "kanalizácia", weight: 1000, subtypes: [
      { legacy_id: 67, name: "upchatá", name_hu: "eldugult", alias: "upchate-kanaly", weight: 1000 },
      { legacy_id: 68, name: "chýbajúci kanalizačný poklop", name_hu: "hiányzó csatornafedél", alias: "chybajuce-kanalizacne-poklopy", weight: 900 },
      { legacy_id: 188, name: "poškodený kanalizačný poklop", name_hu: "megrongált csatornafedél", alias: "poškodený kanalizačný poklop", weight: 800 },
      { legacy_id: 69, name: "havária kanalizačného potrubia", name_hu: "szennyvízcsõ vészhelyzet", alias: "havarie-kanalizacneho-potrubia", weight: 700 }
    ] },
    { legacy_id: 189, name: "osvetlenie", name_hu: "közvilágítás", alias: "osvetlenie", weight: 900, subtypes: [
      { legacy_id: 72, name: "chýbajúce/nedostatočné", name_hu: "hiányzó/hiányos", alias: "chybajuce-nedostatocne-osvetleni", weight: 0 },
      { legacy_id: 70, name: "nefunkčné", name_hu: "nem mûködõ", alias: "nefunkcne-osvetlenie", weight: 0 },
      { legacy_id: 224, name: "nevhodné (silné a pod.)", name_hu: " nem megfelelő (erős stb.)", alias: "nevhodné (silné a pod.)", weight: 0 },
      { legacy_id: 71, name: "poškodené stĺpy", name_hu: "megrongált oszlopok", alias: "poskodene-stlpy-osvetlenia", weight: 0 }
    ] },
    { legacy_id: 74, name: "MHD", name_hu: "városi tömegközlekedés", alias: "mhd", weight: 800, subtypes: [
      { legacy_id: 190, name: "technické problémy", name_hu: "mûszaki problémák", alias: "technické problémy ", weight: 1000 },
      { legacy_id: 191, name: "meškanie spojov", name_hu: "késés", alias: "meškanie spojov", weight: 900 },
      { legacy_id: 192, name: "poškodené vozidlo", name_hu: "megrongált gépjármû", alias: "poškodené vozidlo ", weight: 800 },
      { legacy_id: 193, name: "zlé nastavenie cestovného poriadku", name_hu: "rosszul beállított menetrend", alias: "zlé nastavenie", weight: 700 }
    ] },
    { legacy_id: 194, name: "webová stránka mesta", name_hu: "a település honlapja", alias: "webová stránka mesta", weight: 700, subtypes: [
      { legacy_id: 195, name: "chýbajúce informácie", name_hu: "hiányzó információk ", alias: "chýbajúce informácie", weight: 0 },
      { legacy_id: 196, name: "neaktuálne informácie", name_hu: "nem aktuális információk", alias: "neaktuálne informácie", weight: 0 },
      { legacy_id: 198, name: "nefunkčná stránka", name_hu: "nem mûködõ honlap", alias: "nefunkčná stránka", weight: 0 },
      { legacy_id: 197, name: "nesprávne informácie", name_hu: "helytelen információk", alias: "nesprávne informácie", weight: 0 }
    ] },
    { legacy_id: 199, name: "rozvodné siete", name_hu: "közmûhálózat", alias: "rozvodné siete", weight: 600, subtypes: [
      { legacy_id: 201, name: "nebezpečný kábel", name_hu: "veszélyes vezeték", alias: "nebezpečný kábel", weight: 0 },
      { legacy_id: 200, name: "poškodená rozvodná skriňa", name_hu: "megrongált villanydoboz", alias: "poškodená rozvodná skriňa", weight: 0 }
    ] },
    { legacy_id: 73, name: "iné", name_hu: "egyéb", alias: "ine", weight: 100 },
    { legacy_id: 240, name: "zdieľaná mobilita", name_hu: "közösségi közlekedés", alias: "zdielana-mobilita", weight: 0, subtypes: [
      { legacy_id: 244, name: "iné", name_hu: "egyéb", alias: "ine", weight: 0 },
      { legacy_id: 242, name: "nevhodne umiestnené parkovisko", name_hu: "rossz helyen kijelölt parkolóhely", alias: "nevhodne-umiestnene-parkovisko", weight: 0 },
      { legacy_id: 241, name: "nevhodne zaparkovaný dopravný prostriedok", name_hu: "rossz helyen leparkolt közlekedési eszköz", alias: "nevhodne-zaparkovany-dp", weight: 0 },
      { legacy_id: 243, name: "obmedzenie rýchlosti v zóne", name_hu: "sebességkorlátozás a kijelölt zónában", alias: "obmedzenie-rychlosti-v-zone", weight: 0 }
    ] }
  ] },
  { legacy_id: 21, triage_external_id: 7, name: "Verejný poriadok", name_hu: "Közrend", alias: "verejny-poriadok", description: "stavby, reklama, vandalizmus", description_hu: "építkezések, reklámok, vandalizmus", weight: 400, subcategories: [
    { legacy_id: 20, name: "stavby a budovy", name_hu: "építkezések és épületek ", alias: "stavebne-upravy", weight: 1000, subtypes: [
      { legacy_id: 35, name: "neohlásené stavebné úpravy", name_hu: "illegális építkezés", alias: "neohlasene-stavby-upravy", weight: 1000 },
      { legacy_id: 202, name: "prekračovanie limitov hluku", name_hu: "zaj határértékének túllépése", alias: "prekračovanie limitov hluku", weight: 900 },
      { legacy_id: 203, name: "prekračovanie limitov prašnosti", name_hu: "szálló por határértékének túllépése", alias: "prekračovanie limitov prašnosti", weight: 800 },
      { legacy_id: 204, name: "opustená budova", name_hu: "elhagyott épület", alias: "opustená budova", weight: 700 },
      { legacy_id: 205, name: "zlý stav budovy", name_hu: "rossz állapotban lévõ épület", alias: "zlý stav budovy", weight: 600 }
    ] },
    { legacy_id: 76, name: "vandalizmus", name_hu: "vandalizmus", alias: "vandalizmus", weight: 500, subtypes: [
      { legacy_id: 80, name: "graffiti", name_hu: "graffiti", alias: "graffiti", weight: 1000 },
      { legacy_id: 206, name: "rušenie nočného pokoja", name_hu: "csendrendelet megsértése", alias: "rušenie nočného pokoja", weight: 900 },
      { legacy_id: 207, name: "pitie alkoholu na verejnosti", name_hu: "alkoholfogyasztás közterületen", alias: "pitie alkoholu na verejnosti", weight: 800 }
    ] },
    { legacy_id: 79, name: "reklama", name_hu: "reklám", alias: "ilegalna-reklama-bilborady", weight: 400, subtypes: [
      { legacy_id: 78, name: "vizuálny smog", name_hu: "vizuális szmog", alias: "reklamny-smog", weight: 1000 },
      { legacy_id: 208, name: "nevhodne umiestnená (na chodníku a pod.)", name_hu: "nem megfelelõ elhelyezés", alias: "nevhodne umiestnená", weight: 900 },
      { legacy_id: 209, name: "vylepené plagáty", name_hu: "kiragasztott plakátok", alias: "vylepené plagáty", weight: 800 },
      { legacy_id: 210, name: "nebezpečná (na spadnutie a pod.)", name_hu: "veszélyes ", alias: "nebezpečná", weight: 700 }
    ] },
    { legacy_id: 81, name: "iné", name_hu: "egyéb", alias: "ine", weight: 0 }
  ] },
  { legacy_id: 17, name: "Všetko ostatné", name_hu: "egyéb", alias: "vsetko-ostatne", catch_all: true, description: "Ak žiadna z predošlých kategórií nevystihuje podstatu podnetu, spadá do kategórie všetko ostatné.", description_hu: 'Ha a probléma egyik kategóriába se sorolható be egyértelműen, akkor az "Egyéb" kategóriába tartozik.', weight: 300 }
].each do |category_attributes|
  category = seed_legacy(Issues::Category, category_attributes)

  category_attributes.fetch(:subcategories, []).each do |subcategory_attributes|
    subcategory = seed_legacy(Issues::Subcategory, subcategory_attributes, category: category)

    subcategory_attributes.fetch(:subtypes, []).each do |subtype_attributes|
      seed_legacy(Issues::Subtype, subtype_attributes, subcategory: subcategory)
    end
  end
end

# Created after the legacy import

seed_category("Ostatné") do |category|
  seed_subcategory(category, "iné")
end

seed_category("Verejné služby") do |category|
  seed_subcategory(category, "iné")
end
