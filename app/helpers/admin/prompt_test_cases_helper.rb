module Admin::PromptTestCasesHelper
  def gemini_model_options(models)
    options = models.union([ Gemini::DEFAULT_MODEL ]).map { [ gemini_model_label(_1), _1 ] }

    options_for_select(options, Gemini::DEFAULT_MODEL)
  end

  def gemini_model_label(model)
    name = model == Gemini::DEFAULT_MODEL ? "#{model} (produkcia)" : model
    price = Gemini.price(model)
    return "#{name} · cena neznáma" if price.nil?

    "#{name} · #{number_to_currency(price.input, unit: "$")} / #{number_to_currency(price.output, unit: "$")} za 1M tokenov"
  end

  # Costs of a single run are fractions of a cent, so they keep three significant digits.
  def usd(amount)
    number_to_currency(amount, unit: "$", precision: 3, significant: true, strip_insignificant_zeros: true)
  end
end
