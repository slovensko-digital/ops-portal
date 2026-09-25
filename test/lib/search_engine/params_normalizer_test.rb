require "test_helper"

class SearchEngine::ParamsNormalizerTest < ActiveSupport::TestCase
  test "keeps arrays, scalars and regular hashes as they are" do
    params = ActionController::Parameters.new(
      kategoria: [ "A", "B" ],
      podkategoria: "x",
      nested: { foo: "bar" }
    )

    normalized = SearchEngine::ParamsNormalizer.call(params)

    assert_equal [ "A", "B" ], normalized[:kategoria]
    assert_equal "x", normalized[:podkategoria]
    assert_equal "bar", normalized[:nested][:foo]
    assert_not normalized.permitted?
  end

  test "turns digit-keyed hashes into arrays ordered by index" do
    params = ActionController::Parameters.new(
      Rack::Utils.parse_nested_query("kategoria[1]=B&kategoria[0]=A&obec[0]=X&typ=y")
    )

    normalized = SearchEngine::ParamsNormalizer.call(params)

    assert_equal [ "A", "B" ], normalized[:kategoria]
    assert_equal [ "X" ], normalized[:obec]
    assert_equal "y", normalized[:typ]
  end

  test "normalizes nested digit-keyed hashes" do
    params = ActionController::Parameters.new(
      Rack::Utils.parse_nested_query("filter[tags][0]=a&filter[tags][1]=b")
    )

    normalized = SearchEngine::ParamsNormalizer.call(params)

    assert_equal [ "a", "b" ], normalized[:filter][:tags]
  end

  test "accepts a plain hash" do
    normalized = SearchEngine::ParamsNormalizer.call({ "kategoria" => { "0" => "A" } })

    assert_equal [ "A" ], normalized[:kategoria]
  end
end
