require "test_helper"

class SearchEngine::Controls::TreeAutocompleteTest < ActiveSupport::TestCase
  BRATISLAVA_DISTRICTS = %w[Bratislava-Petržalka Bratislava-Ružinov Bratislava-Staré-Mesto]

  TREE = [
    { label: "Bratislava", value: "Bratislava", children: BRATISLAVA_DISTRICTS.map { { label: _1.delete_prefix("Bratislava-"), value: _1 } } },
    { label: "Nitra", value: "Nitra", children: [] },
    { label: "Súľov", value: "Súľov", children: [ { label: "Centrum", value: "Súľov-Centrum" } ] },
    { label: "Súľov-Hradná", value: "Súľov-Hradná", children: [] }
  ]

  def control
    SearchEngine::Controls::TreeAutocomplete.new(
      param_name: :lokalita,
      label: "Obec / Mestská časť",
      items: TREE,
      filter: ->(scope, _params) { scope },
      filter_label: ->(value) { value }
    )
  end

  def results_with(*localities)
    results = SearchEngine::Results.new
    results.search_params = { lokalita: localities, stav: "Odstúpený" }.with_indifferent_access
    results
  end

  def items_for(*localities)
    control.build_items(results_with(*localities), TREE)
  end

  def item(items, value)
    items.find { _1.value == value }
  end

  test "lists every parent followed by its children" do
    items = items_for

    assert_equal [ "Bratislava", *BRATISLAVA_DISTRICTS, "Nitra", "Súľov", "Súľov-Centrum", "Súľov-Hradná" ], items.map(&:value)
    assert_equal [ 0, 1, 1, 1, 0, 0, 1, 0 ], items.map(&:level)
    assert_equal "Petržalka", item(items, "Bratislava-Petržalka").label
    assert items.none?(&:selected?)
    assert items.none?(&:partial?)
  end

  test "links keep the other params" do
    petrzalka = item(items_for, "Bratislava-Petržalka")

    assert_equal({ "lokalita" => [ "Bratislava-Petržalka" ], "stav" => "Odstúpený" }, petrzalka.add_params)
  end

  test "a selected parent shows all its children as selected" do
    items = items_for("Nitra", "Bratislava")

    assert item(items, "Bratislava").selected?
    assert_not item(items, "Bratislava").partial?
    assert BRATISLAVA_DISTRICTS.all? { item(items, _1).selected? }
    assert_equal [ "Nitra" ], item(items, "Bratislava").remove_params[:lokalita]
  end

  test "unselecting a child of a selected parent keeps its other children" do
    ruzinov = item(items_for("Nitra", "Bratislava"), "Bratislava-Ružinov")

    assert_equal [ "Bratislava-Petržalka", "Bratislava-Staré-Mesto", "Nitra" ], ruzinov.remove_params[:lokalita]
  end

  test "a parent with only some children selected is partial" do
    items = items_for("Bratislava-Petržalka")

    bratislava = item(items, "Bratislava")
    assert_not bratislava.selected?
    assert bratislava.partial?
    assert_equal [ "Bratislava" ], bratislava.add_params[:lokalita]

    assert item(items, "Bratislava-Petržalka").selected?
    assert_not item(items, "Bratislava-Ružinov").selected?
    assert_equal [ "Bratislava-Petržalka", "Bratislava-Ružinov" ], item(items, "Bratislava-Ružinov").add_params[:lokalita]
    assert_equal [], item(items, "Bratislava-Petržalka").remove_params[:lokalita]
  end

  test "selecting the last missing child selects the whole parent" do
    ruzinov = item(items_for("Nitra", "Bratislava-Petržalka", "Bratislava-Staré-Mesto"), "Bratislava-Ružinov")

    assert_equal [ "Bratislava", "Nitra" ], ruzinov.add_params[:lokalita]
  end

  test "a value that only looks like a child of another parent is left alone" do
    items = items_for("Súľov-Hradná")

    assert item(items, "Súľov-Hradná").selected?
    assert_not item(items, "Súľov").partial?
    assert_equal [ "Súľov", "Súľov-Hradná" ], item(items, "Súľov").add_params[:lokalita]
  end

  test "links list the values in tree order, values outside the tree last" do
    nitra = item(items_for("Malacky", "Bratislava-Ružinov"), "Nitra")
    same_selection = item(items_for("Bratislava-Ružinov", "Malacky"), "Nitra")

    assert_equal [ "Bratislava-Ružinov", "Nitra", "Malacky" ], nitra.add_params[:lokalita]
    assert_equal nitra.add_params, same_selection.add_params
  end

  test "removing a chip keeps the rest of the selection" do
    results = results_with("Nitra", "Bratislava-Petržalka", "Bratislava-Ružinov")
    control.add_applied_filter(results)

    district_chip = results.applied_filters.find { _1.label == "Bratislava-Ružinov" }

    assert_equal [ "Nitra", "Bratislava-Petržalka" ], district_chip.remove_filter_params[:lokalita]
  end
end
