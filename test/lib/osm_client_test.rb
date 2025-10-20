require "test_helper"

class OsmClientTest < ActiveSupport::TestCase
  test "builds correct address details for Banská Bystrica Radvaň" do
    details = file_fixture("osm_client_details/banská_bystrica_radvaň.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Centrum" do
    details = file_fixture("osm_client_details/banská_bystrica_centrum.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Fončorda" do
    details = file_fixture("osm_client_details/banská_bystrica_fončorda.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Sásová, Rudlová" do
    details = file_fixture("osm_client_details/banská_bystrica_sásová,_rudlová.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Novoveská Huta" do
    details = file_fixture("osm_client_details/spišská_nová_ves_novoveská_huta.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Ferčekovce" do
    details = file_fixture("osm_client_details/spišská_nová_ves_ferčekovce.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Sídlisko Mier" do
    details = file_fixture("osm_client_details/spišská_nová_ves_sídlisko_mier.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Sídlisko Západ" do
    details = file_fixture("osm_client_details/spišská_nová_ves_sídlisko_západ.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Sídlisko Tarča a Kozí vrch" do
    details = file_fixture("osm_client_details/spišská_nová_ves_sídlisko_tarča_a_kozí_vrch.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Mesto - Sever a Telep" do
    details = file_fixture("osm_client_details/spišská_nová_ves_mesto_-_sever_a_telep.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Spišská Nová Ves Mesto Východ a Mesto Juh" do
    details = file_fixture("osm_client_details/spišská_nová_ves_mesto_východ_a_mesto_juh.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("Spišská Nová Ves"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Senica, Šalková, Majer, Uhlisko" do
    details = file_fixture("osm_client_details/banská_bystrica_senica,_šalková,_majer,_uhlisko.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Senica - special case" do
    details = file_fixture("osm_client_details/banská_bystrica_senica_-_special_case.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Iliaš, Rakytovce, Kremnička, Podháj" do
    details = file_fixture("osm_client_details/banská_bystrica_iliaš,_rakytovce,_kremnička,_podháj.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Banská Bystrica Podlavice, Skubín, Uľanka, Jakub, Karlovo" do
    details = file_fixture("osm_client_details/banská_bystrica_podlavice,_skubín,_uľanka,_jakub,_karlovo.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("banska_bystrica"), nil ], [ m, d ]
  end

  test "builds correct address details for Piešťany" do
    details = file_fixture("osm_client_details/piešťany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Piešťany"), m
  end

  test "builds correct address details for Rajec" do
    details = file_fixture("osm_client_details/rajec_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Rajec"), m
  end

  test "builds correct address details for Trstené pri Hornáde" do
    details = file_fixture("osm_client_details/trstené_pri_hornáde_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Trstené pri Hornáde"), m
  end

  test "builds correct address details for Modra" do
    details = file_fixture("osm_client_details/modra_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Modra"), m
  end

  test "builds correct address details for Štítnik" do
    details = file_fixture("osm_client_details/štítnik_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Štítnik"), m
  end

  test "builds correct address details for Trnava" do
    details = file_fixture("osm_client_details/trnava_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Trnava"), m
  end

  test "builds correct address details for Turzovka" do
    details = file_fixture("osm_client_details/turzovka_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Turzovka"), m
  end

  test "builds correct address details for Hlohovec" do
    details = file_fixture("osm_client_details/hlohovec_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Hlohovec"), m
  end

  test "builds correct address details for Nitra" do
    details = file_fixture("osm_client_details/nitra_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Nitra"), m
  end

  test "builds correct address details for Svidník" do
    details = file_fixture("osm_client_details/svidník_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Svidník"), m
  end

  test "builds correct address details for Bánov" do
    details = file_fixture("osm_client_details/bánov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bánov"), m
  end

  test "builds correct address details for Levice" do
    details = file_fixture("osm_client_details/levice_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Levice"), m
  end

  test "builds correct address details for Semerovo" do
    details = file_fixture("osm_client_details/semerovo_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Semerovo"), m
  end

  test "builds correct address details for Stupava" do
    details = file_fixture("osm_client_details/stupava_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Stupava"), m
  end

  test "builds correct address details for Alekšince" do
    details = file_fixture("osm_client_details/alekšince_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Alekšince"), m
  end

  test "builds correct address details for Janova Lehota" do
    details = file_fixture("osm_client_details/janova_lehota_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Janova Lehota"), m
  end

  test "builds correct address details for Studienka" do
    details = file_fixture("osm_client_details/studienka_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Studienka"), m
  end

  test "builds correct address details for Zemianske Kostoľany" do
    details = file_fixture("osm_client_details/zemianske_kostoľany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Zemianske Kostoľany"), m
  end

  test "builds correct address details for Trstená" do
    details = file_fixture("osm_client_details/trstená_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Trstená"), m
  end

  test "builds correct address details for Lendak" do
    details = file_fixture("osm_client_details/lendak_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Lendak"), m
  end

  test "builds correct address details for Letanovce" do
    details = file_fixture("osm_client_details/letanovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Letanovce"), m
  end

  test "builds correct address details for Myjava" do
    details = file_fixture("osm_client_details/myjava_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Myjava"), m
  end

  test "builds correct address details for Bošáca" do
    details = file_fixture("osm_client_details/bošáca_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bošáca"), m
  end

  test "builds correct address details for Teplička" do
    details = file_fixture("osm_client_details/teplička_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Teplička"), m
  end

  test "builds correct address details for Pečovská Nová Ves" do
    details = file_fixture("osm_client_details/pečovská_nová_ves_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Pečovská Nová Ves"), m
  end

  test "builds correct address details for Chmeľnica" do
    details = file_fixture("osm_client_details/chmeľnica_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Chmeľnica"), m
  end

  test "builds correct address details for Sečovce" do
    details = file_fixture("osm_client_details/sečovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Sečovce"), m
  end

  test "builds correct address details for Žiar nad Hronom" do
    details = file_fixture("osm_client_details/žiar_nad_hronom_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Žiar nad Hronom"), m
  end

  test "builds correct address details for Vysoké Tatry" do
    details = file_fixture("osm_client_details/vysoké_tatry_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Vysoké Tatry"), m
  end

  test "builds correct address details for Ochodnica" do
    details = file_fixture("osm_client_details/ochodnica_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Ochodnica"), m
  end

  test "builds correct address details for Horná Súča" do
    details = file_fixture("osm_client_details/horná_súča_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Horná Súča"), m
  end

  test "builds correct address details for Pezinok" do
    details = file_fixture("osm_client_details/pezinok_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Pezinok"), m
  end

  test "builds correct address details for Biely Kostol" do
    details = file_fixture("osm_client_details/biely_kostol_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Biely Kostol"), m
  end

  test "builds correct address details for Nálepkovo" do
    details = file_fixture("osm_client_details/nálepkovo_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Nálepkovo"), m
  end

  test "builds correct address details for Jablonica" do
    details = file_fixture("osm_client_details/jablonica_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Jablonica"), m
  end

  test "builds correct address details for Križovany nad Dudváhom" do
    details = file_fixture("osm_client_details/križovany_nad_dudváhom_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Križovany nad Dudváhom"), m
  end

  test "builds correct address details for Dubnica nad Váhom" do
    details = file_fixture("osm_client_details/dubnica_nad_váhom_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Dubnica nad Váhom"), m
  end

  test "builds correct address details for Dolný Kubín" do
    details = file_fixture("osm_client_details/dolný_kubín_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Dolný Kubín"), m
  end

  test "builds correct address details for Námestovo" do
    details = file_fixture("osm_client_details/námestovo_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Námestovo"), m
  end

  test "builds correct address details for Veľké Úľany" do
    details = file_fixture("osm_client_details/veľké_úľany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Veľké Úľany"), m
  end

  test "builds correct address details for Bystričany" do
    details = file_fixture("osm_client_details/bystričany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bystričany"), m
  end

  test "builds correct address details for Dolný Lopašov" do
    details = file_fixture("osm_client_details/dolný_lopašov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Dolný Lopašov"), m
  end

  test "builds correct address details for Ďurčiná" do
    details = file_fixture("osm_client_details/ďurčiná_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Ďurčiná"), m
  end

  test "builds correct address details for Ivanka pri Dunaji" do
    details = file_fixture("osm_client_details/ivanka_pri_dunaji_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Ivanka pri Dunaji"), m
  end

  test "builds correct address details for Trenčianske Bohuslavice" do
    details = file_fixture("osm_client_details/trenčianske_bohuslavice_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Trenčianske Bohuslavice"), m
  end

  test "builds correct address details for Malacky" do
    details = file_fixture("osm_client_details/malacky_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Malacky"), m
  end

  test "builds correct address details for Liptovský Mikuláš" do
    details = file_fixture("osm_client_details/liptovský_mikuláš_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Liptovský Mikuláš"), m
  end

  test "builds correct address details for Rožkovany" do
    details = file_fixture("osm_client_details/rožkovany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Rožkovany"), m
  end

  test "builds correct address details for Prievidza" do
    details = file_fixture("osm_client_details/prievidza_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Prievidza"), m
  end

  test "builds correct address details for Bátovce" do
    details = file_fixture("osm_client_details/bátovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bátovce"), m
  end

  test "builds correct address details for Bučany" do
    details = file_fixture("osm_client_details/bučany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bučany"), m
  end

  test "builds correct address details for Turany" do
    details = file_fixture("osm_client_details/turany_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Turany"), m
  end

  test "builds correct address details for Bojnice" do
    details = file_fixture("osm_client_details/bojnice_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bojnice"), m
  end

  test "builds correct address details for Vyšná Šebastová" do
    details = file_fixture("osm_client_details/vyšná_šebastová_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Vyšná Šebastová"), m
  end

  test "builds correct address details for Cífer" do
    details = file_fixture("osm_client_details/cífer_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Cífer"), m
  end

  test "builds correct address details for Sabinov" do
    details = file_fixture("osm_client_details/sabinov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Sabinov"), m
  end

  test "builds correct address details for Dvory nad Žitavou" do
    details = file_fixture("osm_client_details/dvory_nad_žitavou_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Dvory nad Žitavou"), m
  end

  test "builds correct address details for Plášťovce" do
    details = file_fixture("osm_client_details/plášťovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Plášťovce"), m
  end

  test "builds correct address details for Dolné Vestenice" do
    details = file_fixture("osm_client_details/dolné_vestenice_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Dolné Vestenice"), m
  end

  test "builds correct address details for Stará Turá" do
    details = file_fixture("osm_client_details/stará_turá_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Stará Turá"), m
  end

  test "builds correct address details for Lozorno" do
    details = file_fixture("osm_client_details/lozorno_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Lozorno"), m
  end

  test "builds correct address details for Senica" do
    details = file_fixture("osm_client_details/senica_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Senica"), m
  end

  test "builds correct address details for Handlová" do
    details = file_fixture("osm_client_details/handlová_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Handlová"), m
  end

  test "builds correct address details for Komárno" do
    details = file_fixture("osm_client_details/komárno_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Komárno"), m
  end

  test "builds correct address details for Púchov" do
    details = file_fixture("osm_client_details/púchov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Púchov"), m
  end

  test "builds correct address details for Zázrivá" do
    details = file_fixture("osm_client_details/zázrivá_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Zázrivá"), m
  end

  test "builds correct address details for Lučenec" do
    details = file_fixture("osm_client_details/lučenec_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Lučenec"), m
  end

  test "builds correct address details for Nová Baňa" do
    details = file_fixture("osm_client_details/nová_baňa_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Nová Baňa"), m
  end

  test "builds correct address details for Spišské Tomášovce" do
    details = file_fixture("osm_client_details/spišské_tomášovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Spišské Tomášovce"), m
  end

  test "builds correct address details for Tešedíkovo" do
    details = file_fixture("osm_client_details/tešedíkovo_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Tešedíkovo"), m
  end

  test "builds correct address details for Banská Bystrica" do
    details = file_fixture("osm_client_details/banská_bystrica_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("banska_bystrica"), m
  end

  test "builds correct address details for Holíč" do
    details = file_fixture("osm_client_details/holíč_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Holíč"), m
  end

  test "builds correct address details for Martin" do
    details = file_fixture("osm_client_details/martin_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Martin"), m
  end

  test "builds correct address details for Jarok" do
    details = file_fixture("osm_client_details/jarok_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Jarok"), m
  end

  test "builds correct address details for Turňa nad Bodvou" do
    details = file_fixture("osm_client_details/turňa_nad_bodvou_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Turňa nad Bodvou"), m
  end

  test "builds correct address details for Brezová pod Bradlom" do
    details = file_fixture("osm_client_details/brezová_pod_bradlom_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Brezová pod Bradlom"), m
  end

  test "builds correct address details for Vranov nad Topľou" do
    details = file_fixture("osm_client_details/vranov_nad_topľou_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Vranov nad Topľou"), m
  end

  test "builds correct address details for Bánovce nad Bebravou" do
    details = file_fixture("osm_client_details/bánovce_nad_bebravou_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Bánovce nad Bebravou"), m
  end

  test "builds correct address details for Rajecké Teplice" do
    details = file_fixture("osm_client_details/rajecké_teplice_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Rajecké Teplice"), m
  end

  test "builds correct address details for Zvolen" do
    details = file_fixture("osm_client_details/zvolen_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Zvolen"), m
  end

  test "builds correct address details for Koškovce" do
    details = file_fixture("osm_client_details/koškovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Koškovce"), m
  end

  test "builds correct address details for Nižný Hrušov" do
    details = file_fixture("osm_client_details/nižný_hrušov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Nižný Hrušov"), m
  end

  test "builds correct address details for Levoča" do
    details = file_fixture("osm_client_details/levoča_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Levoča"), m
  end

  test "builds correct address details for Košeca" do
    details = file_fixture("osm_client_details/košeca_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Košeca"), m
  end

  test "builds correct address details for Drahovce" do
    details = file_fixture("osm_client_details/drahovce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Drahovce"), m
  end

  test "builds correct address details for Žikava" do
    details = file_fixture("osm_client_details/žikava_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Žikava"), m
  end

  test "builds correct address details for Mýtna" do
    details = file_fixture("osm_client_details/mýtna_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Mýtna"), m
  end

  test "builds correct address details for Valaská" do
    details = file_fixture("osm_client_details/valaská_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Valaská"), m
  end

  test "builds correct address details for Hlboké nad Váhom" do
    details = file_fixture("osm_client_details/hlboké_nad_váhom_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Hlboké nad Váhom"), m
  end

  test "builds correct address details for Liptovský Hrádok" do
    details = file_fixture("osm_client_details/liptovský_hrádok_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Liptovský Hrádok"), m
  end

  test "builds correct address details for Malachov" do
    details = file_fixture("osm_client_details/malachov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Malachov"), m
  end

  test "builds correct address details for Hontianske Nemce" do
    details = file_fixture("osm_client_details/hontianske_nemce_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Hontianske Nemce"), m
  end

  test "builds correct address details for Nová Ves nad Žitavou" do
    details = file_fixture("osm_client_details/nová_ves_nad_žitavou_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Nová Ves nad Žitavou"), m
  end

  test "builds correct address details for Ostrov" do
    details = file_fixture("osm_client_details/ostrov_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Ostrov"), m
  end

  test "builds correct address details for Vyšná Myšľa" do
    details = file_fixture("osm_client_details/vyšná_myšľa_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Vyšná Myšľa"), m
  end

  test "builds correct address details for Podhájska" do
    details = file_fixture("osm_client_details/podhájska_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Podhájska"), m
  end

  test "builds correct address details for Kostolište" do
    details = file_fixture("osm_client_details/kostolište_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Kostolište"), m
  end

  test "builds correct address details for Rimavská Baňa" do
    details = file_fixture("osm_client_details/rimavská_baňa_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Rimavská Baňa"), m
  end

  test "builds correct address details for Krásno nad Kysucou" do
    details = file_fixture("osm_client_details/krásno_nad_kysucou_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Krásno nad Kysucou"), m
  end

  test "builds correct address details for Jesenské" do
    details = file_fixture("osm_client_details/jesenské_.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, _ = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal municipalities("Jesenské"), m
  end

  test "builds correct address details for Bratislava Čunovo" do
    details = file_fixture("osm_client_details/bratislava_čunovo.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Čunovo") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Devín" do
    details = file_fixture("osm_client_details/bratislava_devín.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Devín") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Devínska Nová Ves" do
    details = file_fixture("osm_client_details/bratislava_devínska_nová_ves.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Devínska Nová Ves") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Dúbravka" do
    details = file_fixture("osm_client_details/bratislava_dúbravka.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Dúbravka") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Jarovce" do
    details = file_fixture("osm_client_details/bratislava_jarovce.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Jarovce") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Karlova Ves" do
    details = file_fixture("osm_client_details/bratislava_karlova_ves.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Karlova Ves") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Lamač" do
    details = file_fixture("osm_client_details/bratislava_lamač.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Lamač") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Nové Mesto" do
    details = file_fixture("osm_client_details/bratislava_nové_mesto.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Nové Mesto") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Petržalka" do
    details = file_fixture("osm_client_details/bratislava_petržalka.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Petržalka") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Podunajské Biskupice" do
    details = file_fixture("osm_client_details/bratislava_podunajské_biskupice.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Podunajské Biskupice") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Podunajské Biskupice on Vrakuna edge" do
    details = file_fixture("osm_client_details/bratislava_podunajske2.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Podunajské Biskupice") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Rača" do
    details = file_fixture("osm_client_details/bratislava_rača.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Rača") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Rusovce" do
    details = file_fixture("osm_client_details/bratislava_rusovce.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Rusovce") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Ružinov" do
    details = file_fixture("osm_client_details/bratislava_ružinov.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Ružinov") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Staré Mesto" do
    details = file_fixture("osm_client_details/bratislava_staré_mesto.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("stare_mesto_ba") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Vajnory" do
    details = file_fixture("osm_client_details/bratislava_vajnory.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Vajnory") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Vrakuňa" do
    details = file_fixture("osm_client_details/bratislava_vrakuňa.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Vrakuňa") ], [ m, d ]
  end

  test "builds correct address details for Bratislava Záhorská Bystrica" do
    details = file_fixture("osm_client_details/bratislava_záhorská_bystrica.json").read
    address = OsmClient.build_address_details(JSON.parse(details))
    m, d = Municipality.find_by_address(city: address.city, municipality: address.municipality, suburb: address.suburb)

    assert_equal [ municipalities("bratislava"), municipality_districts("Záhorská Bystrica") ], [ m, d ]
  end
end
