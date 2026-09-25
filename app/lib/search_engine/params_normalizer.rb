module SearchEngine
  # Rack parses `foo[]=a&foo[]=b` as an array but `foo[0]=a&foo[1]=b` as a hash
  # keyed by "0", "1", ... Rails never generates the indexed form, but crawlers and
  # other tools re-serialize our links that way. Turn such hashes back into arrays
  # so the filters behave the same for both forms.
  module ParamsNormalizer
    INDEX_KEY = /\A\d+\z/

    def self.call(params)
      hash = params.respond_to?(:to_unsafe_h) ? params.to_unsafe_h : params.to_h
      ActionController::Parameters.new(normalize(hash))
    end

    def self.normalize(value)
      case value
      when Hash
        if value.any? && value.keys.all? { |key| key.to_s.match?(INDEX_KEY) }
          value.sort_by { |key, _| key.to_i }.map { |_, item| normalize(item) }
        else
          value.transform_values { |item| normalize(item) }
        end
      when Array
        value.map { |item| normalize(item) }
      else
        value
      end
    end
    private_class_method :normalize
  end
end
